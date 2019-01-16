# Time Tracking Software

## Build

After starting a second page (task managing) it was obvious that I would need to modularize the app. Mainly because the data store between the pages should be separated. To avoid using a build tool, which would add some setup complexity costs and a special build step after changes to publish it to basex, I tried X-Templates and inline-templates (see https://medium.com/js-dojo/7-ways-to-define-a-component-template-in-vuejs-c04e0c72900d ). But that does not seem to work with components that are nested in the app. String-Templates are a nogo for non-trivial components, because of lacking syntax-highlighting.

So, time to switch to single file vue-components and simple build-chain.

## vue-cli 3

https://cli.vuejs.org/


## ENOSPC no space left on device
npm, atom etc. überwachen mitunter sehr viele Dateien. Das kann zu diesem irreführenden Fehler führen, auch wenn noch genug Plattenplatz vorhanden ist.
So können die inotify watchers erhöht werden. Der Default von 64k scheint nicht zu reichen...

https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers

npm cache verify


