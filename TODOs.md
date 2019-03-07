# TODOs

## User management

## remove all willhoeft specific details from code / examples

## front end test
* Jasmine

## backend test
* direct db access (crud) for setup / teardown / test
* integrate in npm tooling, run tests in docker container

## Permissions for project leads / members

## public on Github

## Internationalization
* Text/labels
* component localization
* date formats

## refactor
* rename all "working hours" to "attendance"

## reconsider product name "timetracking"
* Add logo / favicon

## Example for OpenOffice integration

## Dashboard
* or remove it if not used?

## billed
* allow to set booking status to "billed"
 * multiple selects and submit possible in "report on projects"
 * booking is locked in dailybooking page
 * backend checks that it cannot be changed
 * status is shown in reports

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
* supply xquery scripts that modify the db from one revision to the next
* supply a script that applies all xquery scripts
* script should be started from outside docker to init/update the data volume
* make sure that web frontend is not accessible / interferes while scripts are applied
 * even better: show progress in web frontend
