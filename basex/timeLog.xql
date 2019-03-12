module namespace page = 'http://basex.org/modules/web-page';
import module namespace session = "http://basex.org/modules/session";
declare namespace rnd = "java.security.SecureRandom";

(: TODO: change module namespace to something more meaningful. E.g. github page :)

(:~
 : Forwards to ui index
 :)
declare
  %rest:path("/")
  %rest:GET
  %perm:allow("all")
function page:redirectIndex() as empty-sequence() {
  <rest:redirect>ui/index.html</rest:redirect>
};

(:~
 : Serve static files
 : @param  $file  file or unknown path
 : @return rest binary data
 :)
declare
  %rest:path("ui/{$file=.+}")
  %rest:GET
  %perm:allow("all")
function page:file(
  $file as xs:string
) as item()+ {
  let $path := file:base-dir() || 'ui/' || $file
  return (
    web:response-header(
      map { 'media-type': web:content-type($path) },
      map { 'Cache-Control': 'max-age=3600,public' }
    ),
    file:read-binary($path)
  )
};

(: TODO: remove GET method when finished testing :)
declare
  %rest:path("user/logout")
  %rest:GET
  %rest:POST
  %perm:allow("all")
function page:logout() as item()* {
  <rest:response>
    <http:response status="200">
      <http:header name="Content-Language" value="en"/>
    </http:response>
  </rest:response>,
  "Logged out",
  session:close()
};

(: TODO: DO NOT use url-params for authentication. Credentials appear in all logs! :)
(: TODO: remove GET method when finished testing :)
declare
  %rest:path("user/login")
  %rest:query-param("login", "{$login}")
  %rest:query-param("password", "{$password}")
  %rest:GET
  %rest:POST
  %rest:produces("text/plain; charset=utf-8")
  %perm:allow("all")
function page:login($login as xs:string, $password as xs:string) as item()* {
  let $staffmember := db:open("timetracking")/staff/staffmember[alias=$login]
  let $auth := $staffmember/authentication[@type='local']
  return if ($auth and page:checkLocalAuthentication($password, $auth))
  then (
    session:set('staffmemberId', $staffmember/@id)
  ) else (
    <rest:response>
      <http:response status="401">
        <http:header name="Content-Language" value="en"/>
      </http:response>
    </rest:response>,
    "Authentication failed"
  )
};

declare
  function page:createLocalAuthentication($password as xs:string) as element(authentication) {
    let $salt := page:salt()
    let $hash := crypto:hmac($password, $salt, 'sha256', 'base64')
    return
      <authentication type="local">
        <hash type="hmac_sha256" salt="{$salt}">{$hash}</hash>
      </authentication>
};

declare function page:checkLocalAuthentication($password as xs:string, $auth as element(authentication)) as xs:boolean{
  page:timeConstantEqual(xs:base64Binary(crypto:hmac($password, xs:base64Binary($auth/hash/@salt), 'sha256', 'base64')), xs:base64Binary($auth/hash/text()))
};

(: secure random 256 bit salt :)
declare
  function page:salt() as xs:base64Binary {
    let $random := rnd:new()
    return bin:from-octets(for-each(rnd:generateSeed($random, xs:int(32)), function($i as xs:int) {$i + 128}))
};

(: Time constant string comparison :)
declare
  function page:timeConstantEqual($a as xs:base64Binary, $b as xs:base64Binary) as xs:boolean {
    (bin:length($a) = bin:length($b)) and bin:unpack-unsigned-integer(bin:xor($a, $b), 0, bin:length($a)) = 0
};

(:~
 : Permission check: all api functions need logged-in user
 : TODO: www-authenticate is set to Basic realm="BaseX" and cannot be overridden? Change in web.xml if necesary.
 :)
declare %perm:check('api/') function page:checkApp() {
  let $staffmemberId := session:get('staffmemberId')
  where empty($staffmemberId)
  return (
    <rest:response>
      <http:response status="401">
        <http:header name="Content-Language" value="en"/>
      </http:response>
    </rest:response>,
    "Authentication needed"
  )
};

(:~
 : timetrack API
 :)

declare
  %rest:path("api/timetrack/{$date}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:timetrack-get($date as xs:date) as element(workingday) {
    let $staffmemberId := session:get('staffmemberId')
    return
      db:open("timetracking")/timetrack/workingday[@date=$date and @staffmemberId=$staffmemberId] ?:
        <workingday date="{fn:adjust-date-to-timezone($date, [])}" staffmemberId="{$staffmemberId}" />
};

declare
  %rest:path("api/timetrack")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:timetrack-get() as element(workingday)  {
    page:timetrack-get(current-date())
};

declare
  %rest:path("api/timetrack")
  %rest:POST("{$t}")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:timetrack-post($t as document-node()) as empty-sequence() {
    let $xsdWorkingday := doc("schemas/workingday.xsd")
    let $doc := db:open("timetracking")/timetrack
    let $memberId := session:get('staffmemberId')
    let $dbt := $doc/workingday[@date=$t/workingday/@date and @staffmemberId=$memberId]
    return copy $tn := $t
    modify (
        (: TODO: validate that all task ids are valid and valid for the user :)
        (: TODO: validate that the root node is "workingday" (schema has many elements) :)
        validate:xsd($t, $xsdWorkingday),
        replace value of node $tn/workingday/@staffmemberId with $memberId
    )
    return if ($dbt)
    then replace node $dbt with $tn
    else insert node $tn into $doc
};

(:~
 : tasks API
 :)

declare
  %rest:path("api/tasks")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:tasks-get() as element(tasks) {
    let $db := db:open("timetracking")/taskRevisions
    return $db/tasks[@rev=max(../tasks/@rev)]
};

(:
    Saves a new revision of the complete task hierarchy. Generates new ids for all new elements.
:)
declare
  %rest:path("api/tasks")
  %rest:POST("{$t}")
  %rest:produces("application/xml", "text/xml")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:tasks-post($t as document-node()) as empty-sequence() {
    (: admin:write-log(concat('POST tasks:', serialize($t)), 'DEBUG') :)
    let $xsdTasks := doc("schemas/tasks.xsd")
    let $db := db:open("timetracking")/taskRevisions
    let $dbt := $db/tasks[@rev=max(../tasks/@rev)] ?: <tasks/>
    return
        copy $tn := $t
        modify (
            (: TODO: make an additional check that all ids are unique :)
            validate:xsd($t, $xsdTasks),
            replace value of node $tn/tasks/@rev with $dbt/@rev + 1,
                (: adding @id to new elements :)
                let $maxId := max((0, $db//*/@id))
                for $e in $tn//(projectGroup, project, taskGroup, task)[@status='new']
                count $i
                return (
                    replace value of node $e/@status with 'open',
                    replace value of node $e/@id with $maxId + $i
                )
        )
        return insert node $tn into $db

};

declare
  %rest:path("api/tasks/{$staffmemberId}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:tasks-get-by-staffmember($staffmemberId as xs:string) as element(tasks) {
    <tasks>{
        let $db := db:open("timetracking")/taskRevisions
        let $dbt := $db/tasks[@rev=max(../tasks/@rev)]
        for $t in ($dbt//task[member[@staffmemberId=$staffmemberId] and not(ancestor-or-self::*[@status='locked'])]) return
          <task>
            { $t/@* }
            {
              for $p in ($t/ancestor::*/@title) return
                <path title="{$p}" />
            }
          </task>
      }
    </tasks>
};


(: Reports :)

(: Booked days overview with sum of work, breaks and bookings  :)
(: TODO: filter on staffMember / authorized user :)
(: TODO: add infos about weekends, holidays, vacations, sickness :)
declare
  %rest:path("api/report/days/{$dateFrom}/{$dateTo}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-get-days($dateFrom as xs:date, $dateTo as xs:date) as element(workingdays){
      <workingdays>
      {
        attribute dateFrom {fn:adjust-date-to-timezone($dateFrom, [])},
        attribute dateTo {fn:adjust-date-to-timezone($dateTo, [])},
        let $db := db:open("timetracking")
        let $wds := $db/timetrack/workingday[@date>=$dateFrom and @date<$dateTo]
        for $wd in ($wds)
        return
          <workingday date="{$wd/@date}">
            {$wd/workingtime}
            <workingtimeSum>{sum($wd/workingtime/xs:dayTimeDuration(@duration))}</workingtimeSum>
            {$wd/break}
            <breakSum>{sum($wd/break/xs:dayTimeDuration(@duration))}</breakSum>
            <bookingSum>{sum($wd/booking/xs:dayTimeDuration(@duration))}</bookingSum>
        </workingday>
      }
      </workingdays>
};


(: Bookings from (included) / to (excluded). Multiple filters are connected as "or" :)
declare
  %rest:path("api/report/bookings/{$dateFrom}/{$dateTo}")
  %rest:query-param("projectTitle", "{$projectTitle}")
  %rest:query-param("billable", "{$billable}")
  %rest:query-param("sort", "{$sort}", "date")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:timetrack-get-bookings($dateFrom as xs:date, $dateTo as xs:date, $projectTitle as xs:string*, $billable as xs:string*, $sort as xs:string*) as element(bookings) {
      <bookings>
      {
        attribute dateFrom {fn:adjust-date-to-timezone($dateFrom, [])},
        attribute dateTo {fn:adjust-date-to-timezone($dateTo, [])},
        (: TODO if necessary return active filters as multiple elements
        if (exists($projectTitle)) then
          attribute projectTitle {$projectTitle},
        if (exists($billable)) then
          attribute billable {$billable},
        :)
        let $db := db:open("timetracking")
        let $wds := $db/timetrack/workingday[@date>=$dateFrom and @date<$dateTo]
        let $tasks := page:tasks-get()
        for $wd in ($wds), $b in ($wd/booking), $t in ($tasks//task[@id = $b/@taskId]), $p in ($t/ancestor::project)
        where
          not (exists($projectTitle)) or ($p/@title = $projectTitle)
        where
          not (exists($billable)) or ($b/@billable = $billable)
        order by
          (if ($sort = 'date') then $wd/@date)
        order by
          (if ($sort = '-date') then $wd/@date) descending
        return
          <booking date="{$wd/@date}">
          {
            $b/(@duration, @billable),
            <project>
            {
              $p/@title/data()
            }
            </project>,
            <task>
              {
                $t/@title/data()
              }
            </task>,
            $b/description
          }
          </booking>
      }
      </bookings>
};
