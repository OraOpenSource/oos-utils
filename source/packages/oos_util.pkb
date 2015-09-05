create or replace package body oos_util
as
  -- CONSTANTS
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';


  -- ******** PRIVATE ********

  /**
   * Internal logging procedure.
   * Requires Logger to be installed only while developing.
   * -- TODO mdsouza: conditional compilation notes
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  -
   *
   * @author Martin D'Souza
   * @created 17-Aug-2015
   * @param p_message Item to log
   * @return TODO
   */
  procedure log(
    p_mesage in varchar2)
  as
    $if $$oos_util_debug $then
      l_scope logger_logs.scope%type := gc_scope_prefix || 'log';
    $end

  begin
    $if $$oos_util_debug $then
      logger.log(p_message, l_scope);
    $else
      null;
    $end
  end log;

  -- ******** PUBLIC ********

  /**
   * Converts parameter to varchar2
   *
   * Notes:
   *  - Need to call this tochar instead of to_char since there will be a conflict when calling it
   *  - Code copied from Logger: https://github.com/OraOpenSource/Logger
   *
   * Related Tickets:
   *  - #11
   *
   * @author Martin D'Souza
   * @created 07-Jun-2014
   * @param p_value
   * @return varchar2 value for p_value
   */
  function tochar(
    p_val in number)
    return varchar2
  as
  begin
    return to_char(p_val);
  end tochar;

  function tochar(
    p_val in date)
    return varchar2
  as
  begin
    return to_char(p_val, gc_date_format);
  end tochar;

  function tochar(
    p_val in timestamp)
    return varchar2
  as
  begin
    return to_char(p_val, gc_timestamp_format);
  end tochar;

  function tochar(
    p_val in timestamp with time zone)
    return varchar2
  as
  begin
    return to_char(p_val, gc_timestamp_tz_format);
  end tochar;

  function tochar(
    p_val in timestamp with local time zone)
    return varchar2
  as
  begin
    return to_char(p_val, gc_timestamp_tz_format);
  end tochar;

  function tochar(
    p_val in boolean)
    return varchar2
  as
  begin
    return case when p_val then 'TRUE' else 'FALSE' end;
  end tochar;

  /**
   * Checks if string is numeric
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #15
   *
   * @author Trent Schafer
   * @created 05-Sep-2015
   * @param p_str String to validate
   * @return True of p_str is number
   */
  function is_number(p_str in varchar2)
    return boolean
  as
    l_num number;
  begin
    l_num := to_number(p_str);
    return true;
  exception
    when value_error then
      return false;
  end is_number;


  /**
   * Checks if string is a valid date
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #20
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param p_str
   * @param p_date_format
   * @return True if date is valid
   */
  function is_date(
    p_str in varchar2,
    p_date_format in varchar2)
    return boolean
  as
    l_date date;
  begin
    l_date := to_date(p_str, p_date_format);
    return true;
  exception
    when others then -- Using a when others since date format could also be invalid
      return false;
  end is_date;



end oos_util;
/
