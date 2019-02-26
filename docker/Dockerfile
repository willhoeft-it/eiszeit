# TODO: this is just a sketch. Not ready, yet!
# Base image, see https://hub.docker.com/r/basex/basexhttp/
FROM basex/basexhttp:9.1.2
# LABEL maintainer="Maintainer <maintainer@example.org>"
COPY ../basex/* /srv/basex/webapp/timetracking
# Copy built frontend (npm run build)
COPY ../frontend/dist /srv/basex/webapp/timetracking/static
# TODO: remove dba, chat, etc.
# TODO: remove / disable webdav
EXPOSE 8984
# TODO: script to init volume with empty database
# TODO: update script to update to database to a newer version
VOLUME ["/srv/basex/data"]
