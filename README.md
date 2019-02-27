# Time Tracking Software

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
TODO: how to setup a nice dev environment with basex. Either with basex in docker or with a dedicated install.

## vue-cli 3

https://cli.vuejs.org/


## ENOSPC no space left on device
npm, atom etc. überwachen mitunter sehr viele Dateien. Das kann zu diesem irreführenden Fehler führen, auch wenn noch genug Plattenplatz vorhanden ist.
So können die inotify watchers erhöht werden. Der Default von 64k scheint nicht zu reichen...

Problem lag dann aber doch an BTRFS. Speicherplatz für Metadaten war aufgebraucht. Ein rebalance war nötig.

https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers

npm cache verify

## vuetify docs
Because the docs may not be available in the used version online, check it out and compile the version you need:

'''
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
