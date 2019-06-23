# Eiszeit Track & Report

## What it is
Eiszeit tracks the time you spend on tasks and projects and allows you to report to project leads and customers of how much time has been spent for them and how much of it can be billed. It will also allow to report on working time contracted between employee and employer. For the latter it is planned (but not yet implemented) to take into account the individual contracted hours, contracted vacation days, public holidays, illnesses, etc.

## Focus
This application is meant to be efficient and not to get into your way, especially in daily repeating tasks like booking your attendance and project hours. It might not (and probably never will) ship with all bells and whistles that other software has, but it is meant to be as open as possible. So it should always be easy to integrate with other software.

## What it isn't
It's not a project planning tool. The tool is meant to report in retrospect and not to make plans for the future. Projects often go on for much longer than thought, but their structure often changes in between. From my year long experience it never pays to set up a very detailed project structure for reporting. In the end, all you want to know is what can be billed, what not and what may be in dispute.
It's not a (human) resource planning tool. Again, this software is meant to report over the past, not the future.
It's also neither meant to be nor suited to monitor employees against their will. In fact we strongly believe that this application helps to relieve tensions between employee and employer by providing tools for transparency, reliability and modern flextime arrangements.

## Maturity
Eiszeit is in alpha stage. It is not (yet) meant to be used in production. If you do, please take care! Primarily, you might want to learn more about the underlying [BaseX database](http://www.basex.org/), e.g. how to make backups of it and how to query and migrate your data, just in case the front-end is not working as expected.

Eiszeit grows on a as needed basis. "We eat our own dog food" and add features as we need them and as we see them fit best.

### What's missing, but planned
* Feedback from you and others. When developers use their own products, they sometimes oversee the obvious.
* Authentication rewrite. You still get an ugly browser auth dialog. Please click "cancel" twice and then login. Sorry.
* Permissions. Right now, everybody is allowed to do almost anything. There will be [RBAC](https://en.wikipedia.org/wiki/Role-based_access_control) eventually
* Internationalization. It's all English (but there is not much text anyway), it's all 24h mode, dates in reports are in format dd.mm.yyyy
* Database migration scripts. Data might get lost or become inaccessible after upgrades. But we have some groundwork laid.
* Employee contracted hours and holidays
* Bookings of sickness and vacations
* Management of clients
* "Freezing" of bookings so they cannot be edited after being billed
* "Freezing" of attendance so it cannot be edited after being accepted by HR
* A logo
* Front-end tests. Jasmine coming
* Configuration of user and application settings.
* Documentation

## License

The application is licensed under the [Mozilla Public License 2.0] (LICENSE.md)

## Quick start

TODO

## Technology stack
From user to CPU, Eiszeit is built on
* [Vuetify](https://vuetifyjs.com/en/)
* [Vue](https://vuejs.org/)
* JavaScript / Web
* [RestXQ](http://docs.basex.org/wiki/RESTXQ)
* [BaseX](http://www.basex.org/)
* [Docker](https://www.docker.com/)

## Build

### build frontend
See frontend/README.md

### build backend
Actually nothing to build here. But you may want to run tests (TODO)

### build docker image
Build frontend first, so it will be integrated in the image.
See docker/README.md

## Develop
How to setup a nice dev environment with basex and Vue CLI.

### setup the backend
* setup a basex server
* its often handy to have the admin webapp enabled. Check here http://localhost:8984/dba (default login 'admin', password 'admin')
* make a symlink in its webapps/ folder to your basex/ project folder like this:
  ~/bin/basex/webapp$ ln -s ~/projects/eiszeit/basex eiszeit
* start the server with bin/basexhttp. Check if this works: http://localhost:8984/eiszeit/api/tasks
* if you start from scratch, you need to create the database 'eiszeit' and add the provided files at basex/evolutions/*_init.xml

### setup the frontend
* if necessary, configure the api dev-proxy in frontend/vue.config.js to forward to your basex server
* start the dev frontend in the eiszeit/frontend/ folder with
  npm run serve
* open your browser to the shown URL

Now all changes under the frontend/src/ and basex/ folders should be instantly reflected. Go code!

### run backend tests

TODO

### vuetify docs (optional)
Because the docs may not be available in the used version online, check it out and compile the version you need:

 git clone https://github.com/vuetifyjs/vuetify.git
 cd vuetify
 git checkout v1.4.2

install yarn (alternative npm client, only for vuetify docs):
see https://yarnpkg.com/en/docs/install#debian-stable

 curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
 echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
 sudo apt-get update && sudo apt-get install yarn

 yarn
 yarn build
 cd packages/docs
 yarn dev

http://localhost:8095/en/
