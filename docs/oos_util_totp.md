# OOS_UTIL_TOTP
- [Introduction](#introduction)
- [Constants](#constants)
- [Generate Secret Function](#generate_secret)
- [Format Key URI Function](#format_key_uri)
- [Generate OTP Function](#generate_otp)
- [Validate OTP Function](#validate_otp)

<a href="#introduction"></a>
## Introduction
A PL/SQL implementation of the [Google Authenticator](https://github.com/google/google-authenticator/wiki)'s Time-based One-Time Password algorithm. The code in this package is based on the [work](https://community.oracle.com/thread/3905510) by "Rabbit" from ATEX Media Solutions Pty Ltd.

<a href="#constants"></a>
## Constants
Name | Code | Description
--- | --- | ---
gc_base32 | `gc_base32 constant varchar2(32) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';` | ...
gc_step | `gc_step constant number := 30;` | ...

<a href="#generate_secret"></a>
## Generate Secret Function
Generates a sixteen-character alphanumeric, [Base32](https://en.wikipedia.org/wiki/Base32)-encoded string.

### Syntax
```
select generate_secret
from dual;
```
### Parameters
Name | Description
--- | ---
`p_length` | number default 16
*return* | returns sixteen-character alphanumeric string

<a href="#format_key_uri"></a>
## Format Key URI Function
Returns a URI, [formatted](https://github.com/google/google-authenticator/wiki/Key-Uri-Format) so that can be used to create a QR Code for setting up a entry in Google Authenticator by scanning. After obtaining the URI, create a QR Code to make it easier to create an entry in Google Authenticator.

### Syntax
```
select
  oos_util_totp.format_key_uri(
    p_label_accountname => 'adrian.png@wonderland.com'
    , p_label_issuer => 'Superworld'
    , p_secret => 'JBSWY3DPEHPK3PXP'
    , p_issuer => 'Superworld'
  )
from dual;
```

### Parameters
Name | Description
--- | ---
`p_type` | number default null (currently not supported)
`p_label_accountname` | varchar2
`p_label_issuer` | varchar2
`p_secret` | varchar2
`p_issuer` | varchar2
`p_algorithm` | varchar2 default null (currently not supported)
`p_digits` | number default null (currently not supported)
`p_counter` | number default null (currently not supported)
`p_period` | number default null (currently not supported)
*return* | returns the URI as a string

<a href="#generate_otp"></a>
## Generate OTP Function

### Syntax
```
select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP')
from dual;
```
```
select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP', p_offset => -30)
from dual;
```
### Parameters
Name | Description
--- | ---
`p_secret` | varchar2
`p_offset` | number
*return* | returns six-digit number as a string

<a href="#validate_otp"></a>
## Validate OTP Function
Validate an OTP. The skew parameter allows for a customizable degree of tolerance for clocks that are not in sync.

### Syntax
```
begin
  if oos_util_totp.validate_otp(
    p_secret => 'JBSWY3DPEHPK3PXP'
    , p_otp => 123456
    , p_skew => 30
  ) = 1 then
    dbms_output.put_line('Valid');
  else
    dbms_output.put_line('Failed');
  end if;
end;
```
### Parameters
Name | Description
--- | ---
`p_secret` | varchar2
`p_otp` | number
`p_skew` | number
*return* | returns 1 if the OTP matches, 0 otherwise
