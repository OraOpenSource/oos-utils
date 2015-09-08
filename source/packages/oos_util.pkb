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
    l_max_length pls_integer := p_length - length(l_ellipsis); -- This is the max that the string can be without an ellipsis appended to it.
  begin
    -- TODO mdsouza: look at the cost of doing these checks
    assert(upper(nvl(p_by_word, 'N')) in ('Y', 'N'), 'Invalid p_by_word. Must be Y/N');
    assert(p_length > 0, 'p_length must be a postive number');

    if upper(nvl(p_by_word, 'N')) = 'Y' then
      l_by_word := true;
    end if;

    if length(l_str) <= p_length then
      l_str := l_str;
    elsif length(l_ellipsis) > p_length or l_max_length = 0 then
      -- Can't replace string with ellipsis if it'll return a larger string.
      l_str := substr(l_str, 1, p_length);
    elsif not l_by_word then
      -- Truncate by length
      l_str := trim(substr(l_str, 1, l_max_length)) || l_ellipsis;
    elsif l_by_word then
      -- If string at [max string(length) - ellipsis] and next characters belong to same word
      -- Then need to go back and find last non-word
      if regexp_instr(l_str, '\w{2,}', l_max_length, 1, 0) = l_max_length then
        l_str := substr(
            l_str,
            1,
            -- Find the last non-word and go back one character
            regexp_instr(substr(l_str,1, p_length - length(l_ellipsis)), '\W+\w*$') -1);

        if l_str is null then
          -- This will happen if the length is just slightly greater than the elipsis and first word is long
          l_str := substr(trim(p_str), 1, l_max_length);
        end if;

      else
        -- Find last non-word. Need to reverse the string since Oracle regexp doesn't support lookbehind assertions
        -- Need to do the reverse in a select statement since it's not a PL/SQL function
        with rev_str as (
          select reverse(substr(l_str,1, l_max_length)) str from sys.dual
        )
        select
          -- Unreverse string
          reverse(
            -- Cut the string from the first word char to the end in the reveresed string
            -- Since this is a reversed string, the first word char, is really the last word char
            substr(rev_str.str, regexp_instr(rev_str.str, '\w'))
          )
        into l_str
        from rev_str;

      end if;

      l_str := l_str || l_ellipsis;

      -- end l_by_word
    end if;

    return l_str;
  end truncate_string;

end oos_util;
/
