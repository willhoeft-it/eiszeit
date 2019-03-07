module namespace testp = 'http://basex.org/modules/tests/permissions';

import module namespace page = 'http://basex.org/modules/web-page' at '../timeLog.xql';

declare
  %unit:test
  function testp:void() { () };

declare %unit:test('expected', "err:XPTY0004") function testp:add() {
  123 + 'strings and integers cannot be added'
};

declare
  %unit:test
  function testp:createLocalAuthentication() {
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
  function testp:timeConstantEqual() {
    unit:assert(page:timeConstantEqual(xs:base64Binary('test'), xs:base64Binary('test')), 'trivial test')
};

declare
  %unit:test
  function testp:cryptoHmac() {
    let $password := 'test'
    let $salt := 'salty'
    let $auth :=
      <authentication type="local">
        <hash type="hmac_sha256" salt="{$salt}">{crypto:hmac($password, $salt, 'sha256', 'base64')}</hash>
      </authentication>
    return (
      unit:assert-equals(crypto:hmac($password, $salt, 'sha256', 'base64'), crypto:hmac($password, $salt, 'sha256', 'base64'), 'same inputs, unequal outputs'),
      unit:assert-equals(crypto:hmac($password, $salt, 'sha256', 'base64'), crypto:hmac($password, $auth/hash/@salt, 'sha256', 'base64'), 'same inputs, but from auth')
    )
};

declare
  %unit:test
  function testp:checkLocalAuthentication() {
    let $auth := page:createLocalAuthentication('password')
    return (
      unit:assert(page:checkLocalAuthentication('password', $auth), 'valid password'),
      unit:assert(not(page:checkLocalAuthentication('XXpassword', $auth)), 'invalid password')
    )
};
