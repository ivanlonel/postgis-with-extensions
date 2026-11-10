"""Typed wrapper around the docker CLI: images, PostgreSQL server containers and volumes."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import time
import uuid
from contextlib import ExitStack, contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Final, Self

if TYPE_CHECKING:
    from collections.abc import Generator, Mapping, Sequence

DOCKER: Final = shutil.which("docker") or "docker"
"""The docker CLI."""

LABEL: Final = "io.github.ivanlonel.postgis-with-extensions.test"
"""Label put on every container and volume the tests create."""

LOGS_VARIABLE: Final = "PWE_TEST_LOGS"
"""Environment variable naming a directory where server logs are saved as containers go away."""

PASSWORD: Final = "postgres"  # noqa: S105 -- throwaway password of local test containers
"""Superuser password of the test servers."""

STARTUP_TIMEOUT: Final = 600.0
"""Seconds to wait for a server to accept TCP connections."""

COMMAND_TIMEOUT: Final = 900.0
"""Seconds to wait for a single docker command."""

STARTED_MARKERS: Final = (
    "PostgreSQL init process complete; ready for start up.",
    "PostgreSQL Database directory appears to contain a database; Skipping initialization",
)
"""What docker-entrypoint.sh prints once initialization is over (or skipped)."""


class DockerError(RuntimeError):
    """A docker command failed."""


class ServerExitedError(DockerError):
    """A server container stopped before accepting connections."""


def docker(
    *args: str,
    check: bool = True,
    stdin: str | None = None,
    timeout: float = COMMAND_TIMEOUT,
    merge_stderr: bool = False,
) -> subprocess.CompletedProcess[str]:
    """
    Run a docker CLI command and capture its output.

    :param *args: The arguments after ``docker``.
    :param check: Whether to raise :exc:`DockerError` on a non-zero exit status.
    :param stdin: Text to feed to the command's standard input.
    :param timeout: Seconds to wait for the command to finish.
    :param merge_stderr: Whether to interleave standard error into the captured standard output.
    :return: The finished process.
    :raise DockerError: If ``check`` is true and the command fails.
    """
    process = subprocess.run(  # noqa: S603 -- a fixed executable with an argument list, no shell
        [DOCKER, *args],
        input=stdin,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT if merge_stderr else subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )
    if check and process.returncode != 0:
        msg = f"docker {' '.join(args)} exited with {process.returncode}:\n{process.stderr}"
        raise DockerError(msg)
    return process


@dataclass(frozen=True, slots=True, kw_only=True)
class Image:
    """An image built from this repository (or a previous release of it)."""

    reference: str
    """Image reference: a tag or a digest."""

    pg_major: int
    """PostgreSQL major version."""

    postgis: tuple[int, int]
    """PostGIS major and minor versions."""

    volume: str
    """The image's data volume path."""

    @classmethod
    def inspect(cls, reference: str) -> Self:
        """
        Read the versions and volume path from an image's configuration.

        :param reference: A local image reference.
        :return: The image description.
        """
        config = json.loads(
            docker("image", "inspect", "--format", "{{json .Config}}", reference).stdout
        )
        env = dict(item.partition("=")[::2] for item in config["Env"])
        major, minor, *_ = env["POSTGIS_VERSION"].split(".")
        (volume,) = config["Volumes"]
        return cls(
            reference=reference,
            pg_major=int(env["PG_MAJOR"]),
            postgis=(int(major), int(minor)),
            volume=volume,
        )

    @property
    def libdir(self) -> str:
        """Directory holding the server's shared libraries."""
        return f"/usr/lib/postgresql/{self.pg_major}/lib"


@dataclass(frozen=True, slots=True, kw_only=True)
class Server:
    """A running PostgreSQL container."""

    name: str
    """Container name."""

    image: Image
    """Image the container runs."""

    def exec(self, *args: str, stdin: str | None = None) -> subprocess.CompletedProcess[str]:
        """
        Run a command in the container as the postgres user.

        :param *args: The command and its arguments.
        :param stdin: Text to feed to the command's standard input.
        :return: The finished process, whatever its exit status.
        """
        options = ["--interactive"] if stdin is not None else []
        return docker(
            "exec", *options, "--user", "postgres", self.name, *args, check=False, stdin=stdin
        )

    def spawn(self, *args: str) -> None:
        """
        Start a command in the container as the postgres user, without waiting for it.

        :param *args: The command and its arguments.
        """
        docker("exec", "--detach", "--user", "postgres", self.name, *args)

    def psql(
        self, *args: str, database: str = "postgres", stdin: str | None = None
    ) -> subprocess.CompletedProcess[str]:
        """
        Run psql, stopping at the first error, with unaligned tuples-only output.

        :param *args: Further psql arguments.
        :param database: Database to connect to.
        :param stdin: Script to feed to psql's standard input.
        :return: The finished process, whatever its exit status.
        """
        return self.exec(
            "psql",
            "--no-psqlrc",
            "--quiet",
            "--no-align",
            "--tuples-only",
            "--set",
            "ON_ERROR_STOP=1",
            "--dbname",
            database,
            *args,
            stdin=stdin,
        )

    def query(self, sql: str, *, database: str = "postgres") -> list[str]:
        """
        Run SQL and return its output lines.

        :param sql: The statements.
        :param database: Database to connect to.
        :return: One line per output row, columns separated by ``|``.
        :raise DockerError: If the statements fail.
        """
        process = self.psql("--command", sql, database=database)
        if process.returncode != 0:
            msg = f"{sql!r} failed in {self.name}:\n{process.stderr}"
            raise DockerError(msg)
        return process.stdout.splitlines()

    def scalar(self, sql: str, *, database: str = "postgres") -> str:
        """
        Run a single-value query.

        :param sql: The query.
        :param database: Database to connect to.
        :return: The value, as text.
        """
        return "\n".join(self.query(sql, database=database)).strip()

    def setting(self, name: str) -> str:
        """
        Read a server setting.

        :param name: The setting name.
        :return: Its value, as SHOW prints it.
        """
        return self.scalar(f"SHOW {name}")

    def preloaded(self) -> list[str]:
        """
        List the libraries in shared_preload_libraries.

        :return: The library names, in order.
        """
        return [lib.strip() for lib in self.setting("shared_preload_libraries").split(",") if lib]

    def libraries(self) -> set[str]:
        """
        List the shared libraries installed in the server's library directory.

        :return: The library names, without the ``.so`` suffix.
        """
        output = self.exec("ls", self.image.libdir).stdout
        return {name.removesuffix(".so") for name in output.split() if name.endswith(".so")}

    @contextmanager
    def database(self) -> Generator[str]:
        """
        Create a scratch database from template0, with pgTAP installed, then drop it.

        :yield: The database name.
        """
        name = f"t_{uuid.uuid4().hex[:12]}"
        self.query(f'CREATE DATABASE "{name}" TEMPLATE template0')
        try:
            self.query("CREATE EXTENSION pgtap", database=name)
            yield name
        finally:
            self.query(f'DROP DATABASE "{name}" WITH (FORCE)')

    def logs(self) -> str:
        """
        Fetch the container's output.

        :return: Standard output and error of the container, interleaved as they were written.
        """
        return docker("logs", self.name, check=False, merge_stderr=True).stdout

    def wait_ready(self, timeout: float = STARTUP_TIMEOUT) -> None:
        """
        Wait until initialization is over and the server accepts TCP connections.

        TCP alone isn't proof: init scripts of earlier images restarted the temporary server
        with TCP enabled, so the entrypoint's own message is awaited too.

        :param timeout: Seconds to wait.
        :raise ServerExitedError: If the container stops first.
        :raise TimeoutError: If the server isn't ready in time.
        """
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            status = docker("inspect", "--format", "{{.State.Status}}", self.name).stdout.strip()
            if status in {"exited", "dead"}:
                msg = f"{self.name} exited before accepting connections:\n{self.logs()}"
                raise ServerExitedError(msg)
            if self.exec("pg_isready", "--host", "127.0.0.1", "--quiet").returncode == 0:
                logs = self.logs()
                if any(marker in logs for marker in STARTED_MARKERS):
                    return
            time.sleep(1)
        msg = f"{self.name} didn't accept connections within {timeout:.0f}s:\n{self.logs()}"
        raise TimeoutError(msg)

    def stop(self) -> None:
        """Stop the container, letting PostgreSQL shut down cleanly."""
        docker("stop", "--time", "120", self.name)

    def remove(self) -> None:
        """
        Remove the container and its anonymous volumes.

        When the ``PWE_TEST_LOGS`` environment variable names a directory, the container's output
        is saved there first, as ``<container name>.log``.
        """
        if directory := os.environ.get(LOGS_VARIABLE):
            path = Path(directory)
            path.mkdir(parents=True, exist_ok=True)
            (path / f"{self.name}.log").write_text(self.logs(), encoding="utf-8")
        docker("rm", "--force", "--volumes", self.name, check=False)


def _run_options(
    image: Image,
    *,
    env: Mapping[str, str] | None,
    volume: str | None,
    mounts: Mapping[str, str] | None,
) -> list[str]:
    options = ["--label", LABEL, "--shm-size", "1g", "--env", f"POSTGRES_PASSWORD={PASSWORD}"]
    for key, value in (env or {}).items():
        options += ["--env", f"{key}={value}"]
    if volume is not None:
        options += ["--volume", f"{volume}:{image.volume}"]
    for source, target in (mounts or {}).items():
        options += ["--volume", f"{source}:{target}:ro"]
    return options


def start_server(  # noqa: PLR0913 -- keyword-only container options
    image: Image,
    *,
    role: str = "server",
    env: Mapping[str, str] | None = None,
    volume: str | None = None,
    mounts: Mapping[str, str] | None = None,
    command: Sequence[str] = (),
) -> Server:
    """
    Start a server container and wait until it accepts connections.

    :param image: The image to run.
    :param role: Short name for what the server is for, put in the container name.
    :param env: Extra environment variables.
    :param volume: Named volume to mount at the image's data volume path.
    :param mounts: Host paths to mount read-only, mapped to container paths.
    :param command: Command overriding the image's default.
    :return: The running server.
    """
    name = f"pwe-test-{role}-{uuid.uuid4().hex[:8]}"
    options = _run_options(image, env=env, volume=volume, mounts=mounts)
    docker("run", "--detach", "--name", name, *options, image.reference, *command)
    server = Server(name=name, image=image)
    with ExitStack() as cleanup:
        # Remove the container if it never becomes ready; keep it once it is.
        cleanup.callback(server.remove)
        server.wait_ready()
        cleanup.pop_all()
    return server


def run_once(
    image: Image, *, env: Mapping[str, str] | None = None, command: Sequence[str] = ()
) -> subprocess.CompletedProcess[str]:
    """
    Run a throwaway container in the foreground until it exits.

    :param image: The image to run.
    :param env: Extra environment variables.
    :param command: Command overriding the image's default.
    :return: The finished ``docker run`` process.
    """
    options = _run_options(image, env=env, volume=None, mounts=None)
    return docker("run", "--rm", *options, image.reference, *command, check=False, timeout=300)


@contextmanager
def scratch_volume() -> Generator[str]:
    """
    Create a named volume, removing it afterwards.

    :yield: The volume name.
    """
    name = f"pwe-test-{uuid.uuid4().hex[:12]}"
    docker("volume", "create", "--label", LABEL, name)
    try:
        yield name
    finally:
        docker("volume", "rm", "--force", name, check=False)
