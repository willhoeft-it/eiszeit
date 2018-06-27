# Building Docker Images

We setup npm scripts for a unified build environment to create and maintain the docker images. Based on
 https://gist.github.com/duluca/d13e501e870215586271b0f9ce1781ce/

## Configure
  Configure your docker setup in package.json. Primarily look at those settings:
  * externalPort: the exposed port from which you can access the app.
  * externalDataVol: name of the data volume to store the db data. It will survive during builds, until cleaned by '''npm run docker:clean:data'''

## Install npm libraries
  npm i

## Build
  npm run docker:build : Builds and Tags the image. After first run, you can just use npm run docker:debug.

## Run
  npm run docker:run : Cleans/removes any running or existing containers and starts up a fresh container.

Note: If no previous container exists, there will be an error. Please ignore it, as the new container should be created and started as expected.
Note: The container will be based on the current image. If you made any changes, make sure that you run docker:build before.

  npm run docker:debug : Test (optional), Build, Tag, Run, Tail and launch your app in a browser to test.

## Clean
  npm run docker:clean:data : WARNING: deletes your data volume! Good to start from scratch.

## Deploy
  npm run docker:publish : Voíla, your results are published on the repository you've defined.
