-- Grants privileges for OOS Utils objects from current user to a defined user
-- Use this if storing OOS Utils in its own schema and other schemas reference it.

-- Parameters
define to_user = '&1' -- This is the user to grant the permissions to


whenever sqlerror exit sql.sqlcode

-- Do not modify code under this line as it is auto generated
-- AUTOREPLACE_START

grant execute on oos_util to &to_user;
grant execute on oos_util_apex to &to_user;
grant execute on oos_util_bit to &to_user;
grant execute on oos_util_date to &to_user;
grant execute on oos_util_lob to &to_user;
grant execute on oos_util_string to &to_user;
grant execute on oos_util_validation to &to_user;
grant execute on oos_util_web to &to_user;
