FROM governmentpaas/psql

COPY . /tests
RUN chmod +x /tests/run.sh
ENTRYPOINT ["/tests/run.sh"]