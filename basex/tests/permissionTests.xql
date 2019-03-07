module namespace testp = 'http://basex.org/modules/tests/permissions';

import module namespace page = 'http://basex.org/modules/web-page' at '../timeLog.xql';

declare
  %unit:test
  function testp:createLocalAuthenticationTest() as empty-sequence() {
    let $auth := page:createLocalAuthentication('password')
    return (
      (:
            <authentication type="local">
              <hash type="hmac_sha256" salt="{$salt}">{$hash}</hash>
            </authentication>
      :)
      unit:assert($auth),
      unit:assert($auth/@type='local'),
      unit:assert($auth/hash/@type='hmac_sha256'),
      unit:assert-equals($auth/hash/bin:length(xs:base64Binary(@salt)), 256 div 8, 'salt bit length'),
      unit:assert-equals($auth/hash/bin:length(xs:base64Binary(text())), 256 div 8, 'hash bit length'),
      unit:assert-equals(xs:string($auth/hash/text()), xs:string(crypto:hmac('password', xs:base64Binary($auth/hash/@salt), 'sha256', 'base64')), 'hash')
    )
};

declare
  %unit:test
  function testp:timeConstantEqualTest() as empty-sequence() {
    unit:assert(page:timeConstantEqual(xs:base64Binary('test'), xs:base64Binary('test')), 'trivial test'),
    unit:assert(not(page:timeConstantEqual(xs:base64Binary('tost'), xs:base64Binary('test'))), 'unequal')
};

declare
  %unit:test
  function testp:cryptoHmacTest() as empty-sequence() {
    let $password := 'test'
    let $salt := 'salty'
    return (
      unit:assert-equals(crypto:hmac($password, $salt, 'sha256', 'base64'), crypto:hmac($password, $salt, 'sha256', 'base64'), 'same inputs, unequal outputs')
    )
};

declare
  %unit:test
  function testp:checkLocalAuthenticationTest() as empty-sequence() {
    let $auth := page:createLocalAuthentication('password')
    return (
      unit:assert(page:checkLocalAuthentication('password', $auth), 'valid password'),
      unit:assert(not(page:checkLocalAuthentication('XXpassword', $auth)), 'invalid password')
    )
};

(: TODO: this requires a running basex db and configured port and api path. Maybe helpful: http://docs.basex.org/wiki/RESTXQ_Module#rest:base-uri :)
declare
  function testp:login($login as xs:string, $password as xs:string) as element(http:response){
    http:send-request(
      <http:request method='post'>
      </http:request>,
      'http://localhost:8984/user/login?login=' || $login || '&amp;' || 'password=' || $password
    ) [1]
};

(: TODO: this depends on a user with a known password in the db :)
declare
  %unit:test
  function testp:loginTest() as empty-sequence() {
    let $resp := testp:login('jwi', 'password')
    return (
      unit:assert-equals(number($resp/@status), 200, 'login failed')
    )
};

declare
  %unit:test
  function testp:loginDenialTest() as empty-sequence() {
    let $resp := testp:login('jwi', 'xxxxx')
    return (
      unit:assert-equals(number($resp/@status), 401, 'login not denied')
    )
};
