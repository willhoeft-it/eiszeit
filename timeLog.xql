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
  %rest:path("timetracking/api/timetrack/{$date}.json")
  %rest:GET
  %output:method("text")
  %output:media-type("application/json")
  %rest:produces("application/json")
  function page:timetrack-get-json($date as xs:date) {
    let $wd :=
<map xmlns="http://www.w3.org/2005/xpath-functions" xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation="urn:json https://www.w3.org/TR/xpath-functions-31/schema-for-json.xsd">
    <map key="timetrack">
        <number key="staffmemberId">1</number>
        <map key="workingday">
            <string key="date">2018-05-08</string>
            <array key="workingtime">
                <map>
                  <string key="start">10:00:00</string>
                  <string key="duration">PT6H15M</string>
                  <string key="description">Working in HQ</string>
                </map>
                <map>
                  <string key="start">17:00:00</string>
                  <string key="duration">PT3H</string>
                  <string key="description">Home-Office</string>
                </map>
            </array>
            <array key="break">
                <map>
                    <string key="duration">PT45M</string>
                    <string key="description">Lunch with Bert</string>
                </map>
            </array>
            <array key="booking">
                <map>
                    <number key="taskId">123</number>
                    <string key="duration">PT3H</string>
                    <string key="billable">yes</string>
                    <string key="description">Assembled mappings for bla</string>
                </map>
                <map>
                    <number key="taskId">123</number>
                    <string key="duration">PT3H</string>
                    <string key="billable">no</string>
                    <string key="description">Fixed our bugs</string>
                </map>
                <map>
                    <number key="taskId">123</number>
                    <string key="duration">PT2H</string>
                    <string key="billable">depends</string>
                    <string key="description">Acquired customer documentation</string>
                </map>
                <map>
                    <number key="taskId">456</number>
                    <string key="start">17:00</string>
                    <string key="duration">PT3H</string>
                    <string key="billable">depends</string>
                    <string key="description">Called customer Smith for discussion of product blubb</string>
                </map>
            </array>
        </map>
            
    </map>
</map>
    return (
      json:serialize($wd,  map{'format': 'basic', 'lax': true()} )
    )
    
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


declare
  %rest:path("timetracking/api/timetrack.json")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
  %output:json("format=jsonml")
  function page:timetrack-get-json() {
    page:timetrack-get-json(current-date())
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
 : timelog view
 : @return HTML page
 :)
declare
  %rest:path("timetracking/timeLog")
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
  %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
  %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")

  function page:start() {
    (: requires saxon9he.jar in basex/lib/custom
       db:chop (here as a "pragma" syntax) by default is "yes" and will remove whitespace from the xslt(!) That stupid default could also
       be changed in .basex or at startup.
       See: http://docs.basex.org/wiki/Options#CHOP and https://mailman.uni-konstanz.de/pipermail/basex-talk/2013-March/004768.html
    :)
    
    (# db:chop no #) {
        xslt:transform(doc('timeLog.xml'), doc('_xsltforms/xsltforms.xsl'), map {'baseuri':'http://localhost:8984/timetracking/_xsltforms/', 'xsltforms_home':'/home/jwi/bin/basex/webapp/timetracking/_xsltforms/'})
    }
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
