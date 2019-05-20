# Time Tracking Software

## What it is
It tracks the time you spend on tasks and projects and allows you to report to project leads and customers how much time has been spent on them and how much of it can be billed. It will also allow to report on working time contracted between employee and employer. For the latter it is planned (but not yet implemented) to take into account the individual contracted hours, contracted vacation days, public holidays, illnesses, etc.

## Focus

TODO: focus on key features: usability. etc.

## What it isn't
It's not a project planning tool. The tool is meant to report in retrospect and not to make plans for the future. Projects often go on for much longer than thought, but their structure often changes in between. From my year long experience it never pays to set up a very detailed project structure for reporting. In the end, all you want to know is what can be billed, what not and what may be in dispute.
It's not a (human) resource planning tool. Again, this software is meant to report over the past, not the future.

TODO: But an open API will allow you to integrate with all kinds of other software.

## Build

After starting a second page (task managing) it was obvious that I would need to modularize the app. Mainly because the data store between the pages should be separated. To avoid using a build tool, which would add some setup complexity costs and a special build step after changes to publish it to basex, I tried X-Templates and inline-templates (see https://medium.com/js-dojo/7-ways-to-define-a-component-template-in-vuejs-c04e0c72900d ). But that does not seem to work with components that are nested in the app. String-Templates are a nogo for non-trivial components, because of lacking syntax-highlighting. So, time to switch to single file vue-components and simple build-chain.

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
* make a symlink in its webapps/ folder to your basex/ project folder like this:
  jwi@jwi-ThinkPad-T460s:~/bin/basex/webapp$ ln -s ~/projects/timetracking/basex timetracking
* start the server with bin/basexhttp. Check if this works: http://localhost:8984/timetracking/api/tasks
* if you start from scratch, you need to create the database 'timetracking' and add the provided files at basex/evolutions/*_init.xml
* its often handy to have the admin webapp enabled. Check here http://localhost:8984/dba (default login 'admin', password 'admin')

### setup the frontend
* if necessary, configure the api dev-proxy in frontend/vue.config.js to forward to your basex server
* start the dev frontend in the timetracking/frontend/ folder with
  npm run serve
* open your browser to the shown URL

Now all changes under the frontend/src/ and basex/ folders should be instantly reflected. Go code!

## vue-cli 3

https://cli.vuejs.org/

npm cache verify

## vuetify docs
Because the docs may not be available in the used version online, check it out and compile the version you need:

 git clone https://github.com/vuetifyjs/vuetify.git
 cd vuetify
 git checkout v1.4.2

### install yarn (alternative npm client)

see https://yarnpkg.com/en/docs/install#debian-stable

 curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
 echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
 sudo apt-get update && sudo apt-get install yarn

 yarn
 yarn build
 cd packages/docs
 yarn dev

http://localhost:8095/en/
