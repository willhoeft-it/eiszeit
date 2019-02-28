# Base image, see https://hub.docker.com/r/basex/basexhttp/
FROM basex/basexhttp:9.1.2
# LABEL maintainer="Maintainer <maintainer@example.org>"
# Because Docker cannot reference files from outside it's context directory, we assume to be started
# in the project directory (..). npm script (see package.json) should take care of that.
COPY --chown=1984 ./basex /srv/basex/webapp/timetracking/
# Copy built frontend (npm run build)
COPY --chown=1984 ./frontend/dist /srv/basex/webapp/timetracking/ui/
# TODO: remove / disable webdav
EXPOSE 8984
VOLUME ["/srv/basex/data"]
CMD ["/usr/local/bin/basexhttp", "-c/srv/basex/webapp/timetracking/evolutions/init.bxs"]
