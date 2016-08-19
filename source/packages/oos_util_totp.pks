/**
 * References:
 * - https://community.oracle.com/thread/3905510
 * - http://jacob.jkrall.net/totp/
 */
create or replace package oos_util_totp
as


  function generate_secret(p_length number default 16) return varchar2;

  function format_key_uri(
    p_type number default null
    , p_label_accountname varchar2
    , p_label_issuer varchar2
    , p_secret varchar2
    , p_issuer varchar2 default null
    , p_algorithm varchar2 default null
    , p_digits number default null
    , p_counter number default null
    , p_period number default null
  ) return varchar2;

  function generate_otp(p_secret varchar2, p_offset number default 0) return varchar2;

  function validate_otp(
    p_secret varchar2
    , p_otp number
    , p_skew number default 30
  ) return number;
end oos_util_totp;
/
