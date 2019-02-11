module namespace page = 'http://basex.org/modules/web-page';

(:~
 : Serve static files
 : @param  $file  file or unknown path
 : @return rest binary data
 :)
declare
  %rest:path("timetracking/static/{$file=.+}")
  %perm:allow("all")
function page:file(
  $file as xs:string
) as item()+ {
  let $path := file:base-dir() || 'static/' || $file
  return (
    web:response-header(
      map { 'media-type': web:content-type($path) },
      map { 'Cache-Control': 'max-age=3600,public' }
    ),
    file:read-binary($path)
  )
};


(: TODO autorization :)

(:~
 : timetrack API
 :)

declare
  %rest:path("timetracking/api/timetrack/{$date}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-get($date as xs:date) {
    <workingday date="{fn:adjust-date-to-timezone($date, [])}"> {
        for $t in (db:open("timetracking")/timetrack/workingday[@date=$date]) return
          $t/*
    }
    </workingday>
};

declare
  %rest:path("timetracking/api/timetrack")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-get() {
    page:timetrack-get(current-date())
};

(: TODO: validate:
  * schema
  * add staff member
:)
declare
  %rest:path("timetracking/api/timetrack")
  %rest:POST("{$t}")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-post($t as document-node()) {
    let $doc := db:open("timetracking")/timetrack
    let $dbt := $doc/workingday[@date=$t/workingday/@date]
    return if ($dbt)
    then replace node $dbt with $t
    else insert node $t into $doc
};


(:~
 : tasks API
 :)

declare
  %rest:path("timetracking/api/tasks")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:tasks-get() {
    let $db := db:open("timetracking")/taskRevisions
    return $db/tasks[@rev=max(../tasks/@rev)]
};

(:
    Saves a new revision of the complete task hierarchy. Generates new ids for all new elements.
:)

declare
  %rest:path("timetracking/api/tasks")
  %rest:POST("{$t}")
  %rest:produces("application/xml", "text/xml")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:tasks-post($t as document-node()) {
    (: admin:write-log(concat('POST tasks:', serialize($t)), 'DEBUG') :)
    let $xsdTasks := doc("tasks.xsd")
    let $db := db:open("timetracking")/taskRevisions
    let $dbt := $db/tasks[@rev=max(../tasks/@rev)] ?: <tasks/>
    return
        copy $tn := $t
        modify (
            validate:xsd($t, $xsdTasks),
            replace value of node $tn/tasks/@rev with $dbt/@rev + 1,
                (: adding @id to new elements :)
                let $maxId := max($db//*/@id)
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
  %rest:path("timetracking/api/tasks/{$staffmemberId}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:tasks-get-by-staffmember($staffmemberId as xs:string) {
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
  %rest:path("timetracking/api/report/days/{$dateFrom}/{$dateTo}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-get-days($dateFrom as xs:date, $dateTo as xs:date) {
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
  %rest:path("timetracking/api/report/bookings/{$dateFrom}/{$dateTo}")
  %rest:query-param("projectTitle", "{$projectTitle}")
  %rest:query-param("billable", "{$billable}")
  %rest:query-param("sort", "{$sort}", "date")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-get-bookings($dateFrom as xs:date, $dateTo as xs:date, $projectTitle as xs:string*, $billable as xs:string*, $sort as xs:string*) {
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
