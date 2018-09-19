module namespace page = 'http://basex.org/modules/web-page';

(:~
 : timetrack api
 :)
 
declare
  %rest:path("timetracking/api/timetrack/{$date}")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  function page:timetrack-get-xml($date as xs:date) {
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
  function page:timetrack-get-xml() {
    page:timetrack-get-xml(current-date())
};


(: TODO: schema validate input :)
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
 : Return static files
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
