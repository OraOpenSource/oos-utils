create or replace package body oos_util
as
  -- CONSTANTS
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  gc_assert_error_number pls_integer := -20000;


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
    p_text in varchar2,
    p_scope in varchar2)
  as
  begin
    $if $$oos_util_debug $then
      logger.log(p_text, p_scope);
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


  /**
   * Validates assertion.
   * Will raise an application error if assertion is false
   *
   * Notes:
   *
   *
   * Related Tickets:
   *  - #19
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param p_condition Boolean condition to validate
   * @param p_msg Message to include in application error if p_condition fails
   */
  procedure assert(
    p_condition in boolean,
    p_msg in varchar2)
  as
  begin
    if not p_condition or p_condition is null then
      raise_application_error(gc_assert_error_number, p_msg);
    end if;
  end assert;


  /**
   * Truncates a string to ensure that it is not longer than p_length
   * If string is > than p_length then an ellipsis (...) will be appended to string
   *
   * Supports following mode:
   *  - By length (default): Will perform a hard parse at p_length
   *  - By word: Will truncate at logical word break
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #5
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param TODO
   * @return Trimmed string
   */
   -- TODO mdsouza: need a better name for this
   -- TODO mdsouza: ellipsize??
  function truncate_string(
    p_str in varchar2,
    p_length in pls_integer,
    -- TODO mdsouza: do we have this called "p_options" to pass in various options?
    -- TODO mdsouza: we may have this more than just "by word"
    p_by_word in varchar2 default 'N'
    -- TODO mdsouza: have p_elipsis as a variable?
  )
    return varchar2
  as
    l_stop_position pls_integer;
    l_str varchar2(32767) := trim(p_str);
    l_ellipsis varchar2(3) := '...';
    l_by_word boolean := false;

    l_scope varchar2(255) := 'oos_util.truncate_string';
  begin
    assert(upper(nvl(p_by_word, 'N')) in ('Y', 'N'), 'Invalid p_by_word. Must be Y/N');
    assert(p_length > 0, 'p_length must be a postive number');

    if upper(nvl(p_by_word, 'N')) = 'Y' then
      l_by_word := true;
    end if;


    if length(l_str) <= p_length then
      l_str := l_str;
    elsif not l_by_word then
      -- Truncate by length
      l_str := trim(substr(l_str, 1, p_length - length(l_ellipsis))) || l_ellipsis;
    elsif l_by_word then
      log('l_by_word', l_scope);

      -- Truncate by word
      l_str := trim(substr(l_str, 1, p_length - length(l_ellipsis)));
      log('l_str: ' || l_str, l_scope);

      -- Find the position of the last word
      -- Need to go back one postion since the regexp will file the begining of the last word)
      l_stop_position := greatest(regexp_instr(l_str, '\w+\W*$')-1, 0);
      log('l_stop_position: ' || l_stop_position, l_scope);

      if l_stop_position = 0 then
        -- Could not find a "last word" so just append ellipsis
        l_str := l_str || l_ellipsis;
      else
        l_str := trim(substr(l_str, 1, l_stop_position)) || l_ellipsis;
      end if;
    end if;

    return l_str;
  end truncate_string;

end oos_util;
/
