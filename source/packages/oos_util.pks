create or replace package oos_util
as
  -- CONSTANTS
  /**
   * @constant gc_date_format default date format
   * @constant gc_timestamp_format default timestamp format
   * @constant gc_timestamp_tz_format default timestamp (with TZ) format
   */
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  -- OOS Util Val Cats
  gc_vals_cat_mime_type constant oos_util_values.cat%type := 'mime-type';

  gc_version constant varchar2(10) := '1.0.0';

  procedure assert(
    p_condition in boolean,
    p_msg in varchar2);

  procedure sleep(
    p_seconds in simple_integer);

end oos_util;
/
