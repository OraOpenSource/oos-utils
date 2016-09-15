create or replace package oos_util
as
  -- CONSTANTS
  /**
   * @constant gc_date_format default date format
   * @constant gc_timestamp_format default timestamp format
   * @constant gc_timestamp_tz_format default timestamp (with TZ) format
   * @constant gc_version String represenation of MAJOR.MINOR.PATCH: Note documented version is just an example.
   * @constant gc_version_major Version number major 1.0.0
   * @constant gc_version_minor Verison number minor 0.1.0
   * @constant gc_version_patch Version number patch 0.0.1
   */
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  -- Version numbers. Useful for anyone writing condtional compilation for OOS Utils
  gc_version_major constant pls_integer := 1;
  gc_version_minor constant pls_integer := 0;
  gc_version_patch constant pls_integer := 0;
  gc_version constant varchar2(30) := gc_version_major || '.' || gc_version_minor || '.' || gc_version_patch;


  -- OOS Util Val Cats
  gc_vals_cat_mime_type constant oos_util_values.cat%type := 'mime-type';

  procedure assert(
    p_condition in boolean,
    p_msg in varchar2);

  procedure sleep(
    p_seconds in simple_integer);

end oos_util;
/
