# TODOs

## Authentication

## Filter for users / staff members

## User management

## build chain
* "production" environment configuration = docker scenario
* '''npm run build'''

## Docker
* Build image from npm, see https://gist.github.com/duluca/d13e501e870215586271b0f9ce1781ce/

## front end test
* Jasmine

## backend test

## public on Github

## Internationalization
* Text/labels
* component localization
* date formats

## refactor
* rename all "working hours" to "attendance"

## reconsider product name "timetracking"
* Add logo / favicon

## Dashboard
* or remove it if not used?

## contracted hours
* per user, define contracts with date interval and working hours per day
* additionally add fixed working week days to contract for specific part-time contracts

## add sickness
* add calendar entry type "sick" that adds contracted hours to that day

## holidays
* add calendar entry type "holiday" that adds contracted hours to that day
* add holiday contingent for each year

## REST API doc
* Swagger (RAML?) generated from backend?

## CI
* build and test from Jenkins

## CD
* to mother
* to docker hub

## public on docker hub

## db update script
* add version attributes to xml root elements
* supply xquery scripts that modify the db from one revision to the next
* supply a script that applies all xquery scripts
* script should be started from outside docker to init/update the data volume
* make sure that web frontend is not accessible / interferes while scripts are applied
 * even better: show progress in web frontend
