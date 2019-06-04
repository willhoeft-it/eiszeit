module namespace page = 'http://basex.org/modules/web-page';
import module namespace session = "http://basex.org/modules/session";
import module namespace sessions = "http://basex.org/modules/sessions";
import module namespace request = "http://exquery.org/ns/request";
declare namespace rnd = "java.security.SecureRandom";

(: TODO: change module namespace to something more meaningful. E.g. github page :)
(: TODO: split into multiple modules, e.g. api, user, util ... :)
(: TODO fix error name space "http://error", also instead of returning a stack trace, a nice error response should be returned in these cases generically. Depending on different QNames, different HTTP status codes could be used :)

(:~
 : Forwards to ui index
 :)
declare
  %rest:path("/")
  %rest:GET
  %perm:allow("all")
function page:redirectIndex() as item() {
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

declare
  %rest:path("api/user/logout")
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

(:
 : Login with login and password.
 :)
declare
  %rest:path("api/user/login")
  %rest:query-param("login", "{$login}")
  %rest:query-param("password", "{$password}")
  %rest:POST
  %perm:allow("all")
function page:login($login as xs:string, $password as xs:string) as item()* {
  let $staffmember := db:open("eiszeit")/staff/staffmember[alias=$login]
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

(:~
 : Make a GET to user/login to check if the session is valid and retrieve base user data.
 :)
declare
  %rest:path("api/user/login")
  %rest:GET
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %perm:allow("all")
function page:login() as item()* {
  let $staffmemberId := session:get('staffmemberId')
  return if (empty($staffmemberId))
  then (
    <rest:response>
      <http:response status="401" />
    </rest:response>,
    <error>Not logged in</error>
  ) else
    <staffmember>  {
      db:open("eiszeit")/staff/staffmember[@id=$staffmemberId]/(@*|*[not(local-name()='authentication')])
    }
    </staffmember>
};

(:~
 : Set user password. Requires an authentication token (e.g. received by mail) or logged in session and old credential.
 : Currently only tokens are accepted that have been created by user "admin".
 :
 : TODO: A token must only be usable once and only within a certain time
 :)
declare
  %rest:path("api/users/user/{$staffmemberId}/password")
  %rest:POST
  %perm:allow("all")
  %rest:query-param("accessToken", "{$accessToken}")
  %rest:query-param("newCred","{$newCred}")
  %rest:query-param("oldCred","{$oldCred}")
  %rest:produces("application/xml", "text/xml")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:user-password-post($staffmemberId as xs:string, $accessToken as xs:string?, $newCred as xs:string, $oldCred as xs:string?) as empty-sequence() {
    let $sessionMid := session:get('staffmemberId')
    let $tokenMid := if($accessToken) then page:checkAccessToken($accessToken, request:path(), true())/mid else ()
    let $authMid := util:or($tokenMid, $sessionMid)
    return (
      admin:write-log('sessionMid: ' || $sessionMid || 'accessToken: ' || string(exists($accessToken)) || ' tokenMid: ' || $tokenMid || ' newCred: ' || string(exists($newCred)), 'DEBUG'),
      if (empty($authMid)) then
        error(QName("http://error", "notAuthenticated"), "authentication needed")
      (: TODO: instead of requiring 'admin' id, check for admin permission :)
      else if ($authMid != $staffmemberId and not($authMid = 'admin')) then
        error(QName("http://error", "adminPrivilegeRequired"), "Admin privilege required")
      else
        let $doc := db:open("eiszeit")/staff
        let $m := $doc/staffmember[@id=$staffmemberId and not(@status='deleted')]
        return
          if (empty($m)) then
            error(QName("http://error", "inaccessibleStaffmember"), "Staffmember unknown or not accessible")
          else if (not($accessToken) and (not($oldCred) or not(page:checkLocalAuthentication($oldCred, $m/authentication[type='local'])))) then
            error(QName("http://error", "passwordCheckFailed"), "Required old password check failed")
          else (
              delete node $m/authentication[@type = ('local', 'preliminary')],
              (: TODO: validate password as in frontend :)
              insert node page:createLocalAuthentication($newCred) into $m
          )
    )
  };

(:~
 : API for user management.
 :
 : Add new user
 :)
declare
  %rest:path("api/users/user")
  %rest:POST("{$u}")
  %rest:produces("application/xml", "text/xml")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:user-post($u as document-node()) as empty-sequence() {
    let $xsdStaff := doc("schemas/staff.xsd")
    return (
      (: TODO: check that element is staffmember and not anything else from schema :)
      validate:xsd($u, $xsdStaff),
      let $db := db:open("eiszeit")/staff
      let $m := $u/staffmember
      let $dbs := $db/staffmember[@id = $m/@id]
      return
        if ($dbs) then
          copy $dbsn := $dbs
          modify (
            delete node $dbsn/(name, givenName, alias, email),
            insert node ($m/name, $m/givenName, $m/alias, $m/email) as first into $dbsn
          )
          return
            replace node $dbs with $dbsn
        else (
          (: alias of non-active (semi-deleted) members are reusable (only ids must be unique forever) :)
          if ($db/staffmember[alias=$m/alias and not(@status='deleted')]) then
            error(QName("http://error", "aliasNotUnique"), "Alias already in active use"),
          (: id = alias or, if taken, = alias_1 or, if taken, = alias_(max n + 1) :)
          let $newId :=
            if($db/staffmember[@id=$m/alias]) then
              if ($db/staffmember[matches(@id, concat('^', $m/alias, '_\d+$'))]) then
                concat($m/alias, '_',
                  number(max(
                    $db/staffmember[matches(@id, concat('^', $m/alias, '_\d+$'))]/replace(@id, concat('^', $m/alias, '_(\d+)$'), '$1')
                  )) + 1
                )
              else
                concat($m/alias, '_1')
            else
              $m/alias
          return
            insert node
              <staffmember id="{$newId}">
                {$m/name, $m/givenName, $m/alias, $m/email}
              </staffmember>
            into $db
        )
    )
};

(:~
 : Delete a user
 :)
declare
  %rest:path("api/users/user/{$id}")
  %rest:DELETE
  %rest:produces("application/xml", "text/xml")
  %updating
  %output:method("xml")
  %output:omit-xml-declaration("no")
  %rest:single
  function page:user-delete($id as xs:string) as empty-sequence() {
    let $db := db:open("eiszeit")/staff
    let $dbs := $db/staffmember[@id = $id]
    return (
      if (not($dbs)) then error(QName("http://error", "unknownStaffmember"), "Staffmember id unknown"),
      delete node $dbs/(name, givenName, email, @status),
      insert node (attribute {'status'}{'deleted'}) into $dbs
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

(: TODO: this "secret" should be generated randomly or passed via ENV on server start :)
declare variable $page:secret := 'secretSECRETsecretSECRET';

declare
  function page:createAccessToken($sid as xs:string, $mid as xs:string, $path as xs:string) as xs:string {
    let $jtoken := json:serialize(
      <json type='object'>
        <sid>{$sid}</sid>
        <mid>{$mid}</mid>
        <path>{$path}</path>
        <ts>{current-dateTime()}</ts>
      </json>,
      map { 'format': 'xquery', 'indent': 'no', 'escape': 'no' }
    )
    let $stoken := xs:string(bin:encode-string($jtoken, 'UTF-8'))
    let $sig := crypto:hmac($stoken, $page:secret, 'sha256', 'base64')
    return concat($stoken, '.', $sig)
};

declare
  function page:checkAccessToken($jwt as xs:string, $path as xs:string, $ignoreSession as xs:boolean?) as element(json) {
    let $parts := tokenize($jwt, '\.')
    let $stoken := $parts[1]
    let $sig := $parts[2]
    let $jtoken := bin:decode-string(xs:base64Binary($stoken), 'UTF-8')
    let $token := json:parse($jtoken)
    return
      (: TODO use page:timeConstantEqual :)
      (:TODO add a max age of timestamp check:)
      (: TODO hide the error details (needed only for debugging) :)
      (:
      if (not((crypto:hmac($stoken, $page:secret, 'sha256', 'base64') = $sig) and
        ($token/json/sid = sessions:ids()) and
        ($token/json/path = $path)
      )) then error(QName("http://error", "invalidAccessToken"), "invalid access token")
      :)
      if (not(crypto:hmac($stoken, $page:secret, 'sha256', 'base64') = $sig)) then
        error(QName("http://error", "invalidAccessToken"), "invalid access token: signature failed")
      else if (not($ignoreSession) and not($token/json/sid = sessions:ids())) then
        error(QName("http://error", "invalidAccessToken"), "invalid access token: session unknown")
      else if (not($token/json/path = $path)) then
        error(QName("http://error", "invalidAccessToken"), "invalid access token: path doesn't match")
      else $token/json
};

(:~
 : Permission check: all api functions need logged-in user.
 : Alternatively a restricted accessToken can be used.
 : TODO: www-authenticate is set to Basic realm="BaseX" and cannot be overridden? Change in web.xml if necesary.
 : TODO: accessToken access should work as if the same user. Currently e.g. api/timetrack/{$date} has no session / staffMemberId set.
 :)
declare
  %perm:check('api/', '{$perm}')
  %rest:query-param("accessToken", "{$accessToken}")
function page:checkApp($perm, $accessToken as xs:string?) {
  let $staffmemberId := session:get('staffmemberId')
  where
    empty($staffmemberId) and not (
      $perm?allow = 'all'
    ) and not (
      $accessToken and
      page:checkAccessToken($accessToken, $perm?path, false()) and
      $perm?method = 'GET'
    )
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
 : Request an access token that can be used to have restricted access to data in his place.
 : The given token must be URL encoded (it might contain '+') and added as accessToken parameter.
 :)
declare
  %rest:path("api/token")
  %rest:GET
  %rest:query-param("path", "{$path}")
  %rest:produces("application/xml", "text/xml")
  %output:method("xml")
  %output:omit-xml-declaration("no")
function page:token-get($path as xs:string) as item()* {
  (: If detailed user permissions are implemented, we will need to check that the user has permission
  on the paths he is requesting the token for. Even then sensitive areas (user settings, server configurations, etc.) should be exempt.
  For now we just limit to some specific paths :)
  let $bc := tokenize($path, '/')
  return
    if (not($bc[1] = '' and $bc[2] = 'api' and $bc[3] = ('timetrack', 'report', 'users'))) then
      error(QName("http://error", "invalidTokenRequest"), "Invalid token request")
    else
      <token>{page:createAccessToken(session:id(), session:get('staffmemberId'), $path)}</token>
};

(:~
 : timetrack API
 :)
 declare
   %rest:path("api/staff")
   %rest:GET
   %rest:produces("application/xml", "text/xml")
   %output:method("xml")
   %output:omit-xml-declaration("no")
 function page:staff-get() as item()* {
   <staff> {
     for $s in (db:open("eiszeit")/staff/staffmember[not(@status='deleted')]) return
       <staffmember>
         { $s/(@*|*[not(local-name()='authentication')]) }
       </staffmember>
   }
   </staff>
 };

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
      db:open("eiszeit")/timetrack/workingday[@date=$date and @staffmemberId=$staffmemberId] ?:
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
    let $doc := db:open("eiszeit")/timetrack
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
    let $db := db:open("eiszeit")/taskRevisions
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
    let $db := db:open("eiszeit")/taskRevisions
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
        let $db := db:open("eiszeit")/taskRevisions
        let $dbt := $db/tasks[@rev=max(../tasks/@rev)]
        for $t in ($dbt//task[staffmemberId=$staffmemberId]) return
          <task status="{if ($t/ancestor-or-self::*[@status='locked']) then 'locked' else $t/@status}">
            { $t/(@id, @billableDefault, @title) }
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
        let $db := db:open("eiszeit")
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
        let $db := db:open("eiszeit")
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
