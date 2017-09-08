create or replace package oos_util_string
as

  -- TYPES

  -- CONSTANTS
  /**
   * @constant gc_default_delimiter Default delimiter for delimited strings
   * @constant gc_cr Carriage Return
   * @constant gc_lf Line Feed
   * @constant gc_crlf Use for new lines.
   */
  gc_default_delimiter constant varchar2(1) := ',';
  gc_cr constant varchar2(1) := chr(13);
  gc_lf constant varchar2(1) := chr(10);
  gc_crlf constant varchar2(2) := gc_cr || gc_lf;

  function to_char(
    p_val in number)
    return varchar2
    deterministic;

  function to_char(
    p_val in date)
    return varchar2
    deterministic;

  function to_char(
    p_val in timestamp)
    return varchar2
    deterministic;

  function to_char(
    p_val in timestamp with time zone)
    return varchar2
    deterministic;

  function to_char(
    p_val in timestamp with local time zone)
    return varchar2;

  function to_char(
    p_val in boolean)
    return varchar2
    deterministic;

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
    
  function sprintf(
    p_str in varchar2,
    p_key_values in t_tab_key_value,
    p_left_pattern in varchar2 default '{',
    p_right_pattern in varchar2 default '}')
    return varchar2;
    
  function sprintf(
    p_str in varchar2,
    p_tab_vc2 in t_tab_vc2,
    p_left_pattern in varchar2 default '{',
    p_right_pattern in varchar2 default '}')
    return varchar2;

  function string_to_table(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr;

  function string_to_table(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr;

  function listunagg(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined;

  function listunagg(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined;

  function reverse(
    p_str in varchar2)
    return varchar2;

  function ordinal(
    p_num in number)
    return varchar2;

end oos_util_string;
/
