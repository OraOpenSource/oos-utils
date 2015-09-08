create or replace package body oos_util_string
as

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
    return to_char(p_val, oos_util.gc_date_format);
  end tochar;

  function tochar(
    p_val in timestamp)
    return varchar2
  as
  begin
    return to_char(p_val, oos_util.gc_timestamp_format);
  end tochar;

  function tochar(
    p_val in timestamp with time zone)
    return varchar2
  as
  begin
    return to_char(p_val, oos_util.gc_timestamp_tz_format);
  end tochar;

  function tochar(
    p_val in timestamp with local time zone)
    return varchar2
  as
  begin
    return to_char(p_val, oos_util.gc_timestamp_tz_format);
  end tochar;

  function tochar(
    p_val in boolean)
    return varchar2
  as
  begin
    return case when p_val then 'TRUE' else 'FALSE' end;
  end tochar;


  /**
   * Truncates a string to ensure that it is not longer than p_length
   * If string is > than p_length then an ellipsis (...) will be appended to string
   *
   * Supports following modes:
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

    l_scope varchar2(255) := 'oos_util_string.truncate_string';
    l_max_length pls_integer := p_length - length(l_ellipsis); -- This is the max that the string can be without an ellipsis appended to it.
  begin
    -- TODO mdsouza: look at the cost of doing these checks
    oos_util.assert(upper(nvl(p_by_word, 'N')) in ('Y', 'N'), 'Invalid p_by_word. Must be Y/N');
    oos_util.assert(p_length > 0, 'p_length must be a postive number');

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

end oos_util_string;
/
