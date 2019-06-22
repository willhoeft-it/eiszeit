# TODOs

## refactor
* rename all "working hours" to "attendance"

## Milestone: go public on Github

------
## Logo "Eiszeit"
* Add logo / favicon

## Add intro start page
* Links to github, issue tracker, docker, wiki, about, etc.

## front end test
* Jasmine

## backend test
* direct db access (crud) for setup / teardown / test
* integrate in npm tooling, run tests in docker container

## Permissions for project leads / members

## Internationalization
* Text/labels
* component localization
* date formats

## switch authentication to JWT
see:
* https://www.oauth.com/oauth2-servers/access-tokens/self-encoded-access-tokens/
* https://www.oauth.com/oauth2-servers/making-authenticated-requests/
* https://mailman.uni-konstanz.de/pipermail/basex-talk/2019-February/014070.html
* https://alligator.io/vuejs/vue-jwt-patterns/
* http://jasonwatmore.com/post/2018/07/06/vue-vuex-jwt-authentication-tutorial-example

Use-Case: integration with OpenOffice needs auth encoded in URL, but it should not contain long-term credentials
Idea:
* (/) Provide link on (reporting) page that includes:
 * URL of this page
 * sort/filter parameters as currently used
 * access-token URL parameter composed of
  * URL of page (without sort/filter)
  * user session id
  * timestamp
  * signature with key that is only known to server (could be generated on start or passed as ENV param)
* (/) Server will provide this link and token on client request, when
 * user is logged in
 * has access rights to the requested URL
* (/) On use of the link, when usual (session) validation fails, server checks:
 * access-token given?
 * signature valid?
 * session id in token still valid?
 * (optional) timestamp not older than configured duration (e.g. 1h)
 * GET request
 * called URL equals URL in token (parameters ignored)
* if all checks succeed, grant access with rights of the user session
* (/) The url can be pasted into a LibreOffice document
* (/) when user is logged out (or session times out and possibly after server restart), all his created tokens are invalid, because the session id check will fail (see above)

## Example for OpenOffice integration

## Client management

## Dashboard
* or remove it if not used?
* Nice fixed reports (in code)
 * Booked / open / billable hours/days this week and previous week
 * Booked / open / billable hours/days this month and previous month
 * For every booked project:
  * booked / billable hours/days this and previous week
  * booked / billable hours/days this and previous month
* Editable and savable report widgets
 * xquery within secured context
 * possible charts:
  * bar chart + text, e.g. billable/non-billable tasks stacked over time
  * gauge + green/yellow/red, e.g. booked hours compared to amount of days * 8
  * pie chart, e.g. unbooked vs. non-billable, billable, depends
  * line chart, e.g. billable hours over time

## db update script
* supply a script that applies all xquery scripts
* script should be started from outside docker to init/update the data volume
* make sure that web frontend is not accessible / interferes while scripts are applied
 * even better: show progress in web frontend

# add healthcheck to docker image
See https://docs.docker.com/engine/reference/#healthcheck
Might need a small script

## user/system configuration
* dark-mode
* start of week
* enable auth tokens
* auth token duration
* ...

## add sickness
* add calendar entry type "sick" that adds contracted hours to that day

## holidays
* add calendar entry type "holiday" that adds contracted hours to that day
* add holiday contingent for each year

## billed
* allow to set booking status to "billed"
 * multiple selects and submit possible in "report on projects"
 * booking is locked in dailybooking page
 * backend checks that it cannot be changed
 * status is shown in reports

## "Freezing" of attendance
* so it cannot be edited after being accepted by HR

## contracted hours
* per user, define contracts with date interval and working hours per day
* additionally add fixed working week days to contract for specific part-time contracts

## REST API doc
* Swagger (RAML?) generated from backend?

## CI
* build and test from Jenkins

## CD
* to mother
* to docker hub

## public on docker hub

## cleanup DB scripts
* truly delete staffmembers, when they are marked as deleted and they are not referenced anywhere
* truly delete tasks, projects, projecGroups, whole revisions etc., when they are marked deleted and there are no bookings on them
