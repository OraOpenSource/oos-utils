-- Grants privileges for OOS Utils objects from current user to a defined user
-- Use this if storing OOS Utils in its own schema and other schemas reference it.

-- Parameters
define to_user = '&1' -- This is the user to grant the permissions to


whenever sqlerror exit sql.sqlcode

-- Do not modify code under this line as it is auto generated
-- AUTOREPLACE_START

create or replace synonym oos_util for &from_user..oos_util;
create or replace synonym oos_util_apex for &from_user..oos_util_apex;
create or replace synonym oos_util_bit for &from_user..oos_util_bit;
create or replace synonym oos_util_crypto for &from_user..oos_util_crypto;
create or replace synonym oos_util_date for &from_user..oos_util_date;
create or replace synonym oos_util_lob for &from_user..oos_util_lob;
create or replace synonym oos_util_string for &from_user..oos_util_string;
create or replace synonym oos_util_totp for &from_user..oos_util_totp;
create or replace synonym oos_util_validation for &from_user..oos_util_validation;
create or replace synonym oos_util_web for &from_user..oos_util_web;
