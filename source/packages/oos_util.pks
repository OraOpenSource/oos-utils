create or replace package oos_util
as
  -- CONSTANTS
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  -- OOS Util Val Cats
  gc_vals_cat_mime_type constant oos_util_vals.cat%type := 'mime-type';

  -- TODO mdsouza: Think about better way to do this so can do coniditional comp
  gc_version constant varchar2(10) := '1.0.0';

  procedure assert(
    p_condition in boolean,
    p_msg in varchar2);

end oos_util;
/
