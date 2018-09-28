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
  * task ids / staff member
  * 
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
    db:open("timetracking")/tasks[1]
};
 
declare
  %rest:path("timetracking/api/tasks/{$staffmemberId}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:tasks-get-by-staffmember($staffmemberId as xs:string) {
    <tasks>{
        for $t in (db:open("timetracking")/tasks//task[member[@staffmemberId=$staffmemberId] and not(ancestor-or-self::*[@status='closed'])]) return
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
