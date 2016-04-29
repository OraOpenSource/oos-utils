create or replace package oos_util_string
as

  -- TYPES
  /**
   * @type tab_vc2 VC2 Nested table
   * @type tab_vc2_arr VC2 associated array
   */
  type tab_vc2 is table of varchar2(32767);
  type tab_vc2_arr is table of varchar2(32767) index by pls_integer;

  -- CONSTANTS
  /**
   * @constant gc_default_delimiter Default delimiter for delimited strings
   */
  gc_default_delimiter constant varchar2(1) := ',';

  function to_char(
    p_val in number)
    return varchar2;

  function to_char(
    p_val in date)
    return varchar2;

  function to_char(
    p_val in timestamp)
    return varchar2;

  function to_char(
    p_val in timestamp with time zone)
    return varchar2;

  function to_char(
    p_val in timestamp with local time zone)
    return varchar2;

  function to_char(
    p_val in boolean)
    return varchar2;

  function truncate(
    p_str in varchar2,
    p_length in pls_integer,
    p_by_word in varchar2 default 'N',
    p_ellipsis in varchar2 default '...')
    return varchar2;

  function sprintf(
    p_str in varchar2,
    p_s1 in varchar2 default null,
    p_s2 in varchar2 default null,
    p_s3 in varchar2 default null,
    p_s4 in varchar2 default null,
    p_s5 in varchar2 default null,
    p_s6 in varchar2 default null,
    p_s7 in varchar2 default null,
    p_s8 in varchar2 default null,
    p_s9 in varchar2 default null,
    p_s10 in varchar2 default null)
    return varchar2;

  function string_to_table(
    p_string in clob,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2_arr;

  function string_to_table(
    p_string in varchar2,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2_arr;

  function listunagg(
    p_string in varchar2,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2 pipelined;

  function listunagg(
    p_string in clob,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2 pipelined;

  function reverse(
    p_string in varchar2)
    return varchar2;

end oos_util_string;
/
