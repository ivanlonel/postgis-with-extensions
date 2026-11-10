-- https://github.com/bigsql/plprofiler
CREATE EXTENSION plprofiler;

SELECT
	pl_profiler_version(),
	pl_profiler_versionstr();
