create or replace package oos_util
as

  -- TYPES
  /**
   * @type tab_num `number` nested table
   * @type tab_num_arr `number` associated array
   * @type tab_vc2 `varchar2` nested table
   * @type tab_vc2_arr `varchar2` associated array
   */
  type tab_num is table of number;
  type tab_num_arr is table of number index by pls_integer;
  type tab_vc2 is table of varchar2(32767);
  type tab_vc2_arr is table of varchar2(32767) index by pls_integer;


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
  gc_date_format constant varchar2(255) := 'YYYY-MM-DD HH24:MI:SS';
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


  function assoc_arr2nested_table(
    p_assoc_arr in oos_util.tab_vc2_arr)
    return oos_util.tab_vc2;

  function assoc_arr2nested_table(
    p_assoc_arr in oos_util.tab_num_arr)
    return oos_util.tab_num;
end oos_util;
/
