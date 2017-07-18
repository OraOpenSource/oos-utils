create or replace package body oos_util_string
as

  /**
   * Converts parameter to varchar2
   *
   * Notes:
   *  - Code copied from Logger: https://github.com/OraOpenSource/Logger
   *
   * @issue 11
   *
   * @example
   *
   * select oos_util_string.to_char(123)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_CHAR(123)---
   * 123
   *
   * @author Martin D'Souza
   * @created 07-Jun-2014
   * @param p_val Number
   * @return string value for p_val
   */
  function to_char(
    p_val in number)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * select oos_util_string.to_char(sysdate)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_CHAR(SYSDATE)---
   * 26-APR-2016 13:57:51
   *
   * @param p_val Date
   * @return string value for p_val
   */
  function to_char(
    p_val in date)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_date_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * select oos_util_string.to_char(systimestamp)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_CHAR(SYSTIMESTAMP)---
   * 26-APR-2016 13:58:24:851908000 -06:00
   *
   * @param p_val Timestamp
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * TODO
   * @param p_val Timestamp with TZ
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp with time zone)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_tz_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * TODO
   *
   * @param p_val Timestamp with local TZ
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp with local time zone)
    return varchar2
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_tz_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(true));
   *   dbms_output.put_line(oos_util_string.to_char(false));
   * end;
   * /
   *
   * TRUE
   * FALSE
   *
   * @param p_val Boolean
   * @return string value for p_val
   */
  function to_char(
    p_val in boolean)
    return varchar2
    deterministic
  as
  begin
    return case when p_val then 'TRUE' else 'FALSE' end;
  end to_char;

  /**
   * Truncates a string to ensure that it is not longer than `p_length`
   * If length of `p_str` is greater than `p_length` then an ellipsis (`...`) will be appended to string
   *
   * Supports following modes:
   *  - By length (default): Will perform a hard parse at `p_length`
   *  - By word: Will truncate at logical word break
   *
   *
   * @issue #5
   *
   * @example
   * select
   *   oos_util_string.truncate(
   *     p_str => comments,
   *     p_length => 20,
   *     p_by_word => 'N'
   *   ) by_word_n,
   *   oos_util_string.truncate(
   *     p_str => comments,
   *     p_length => 20,
   *     p_by_word => 'Y'
   *   ) by_word_y
   * from apex_dictionary
   * where 1=1
   *   and rownum <= 5
   * ;
   *
   * BY_WORD_N            BY_WORD_Y
   * -------------------- --------------------
   * List of APEX buil... List of APEX...
   * Identifies the th... Identifies the...
   * Identifies the na... Identifies the...
   * Identifies the th... Identifies the...
   * Identifies a work... Identifies a...
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param p_str String to truncate
   * @param p_length Max length of final string
   * @param p_by_word Y/N. If Y then will truncate to last word possible
   * @param p_ellipsis ellipsis "..." default
   * @return Trimmed string
   */
  function truncate(
    p_str in varchar2,
    p_length in pls_integer,
    p_by_word in varchar2 default 'N',
    p_ellipsis in varchar2 default '...')
    return varchar2
  as
    l_stop_position pls_integer;
    l_str varchar2(32767) := trim(p_str);
    l_by_word boolean := false;

    l_max_length pls_integer := p_length - length(p_ellipsis); -- This is the max that the string can be without an ellipsis appended to it.

    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin

    -- #122 return null if string is null. Doing first since no need to do extra work if null.
    if l_str is null then
      return null;
    end if;

    -- TODO mdsouza: look at the cost of doing these checks
    oos_util.assert(upper(nvl(p_by_word, 'N')) in ('Y', 'N'), 'Invalid p_by_word. Must be Y/N');
    oos_util.assert(p_length > 0, 'p_length must be a postive number');

    if upper(nvl(p_by_word, 'N')) = 'Y' then
      l_by_word := true;
    end if;

    if length(l_str) <= p_length then
      l_str := l_str;
    elsif length(p_ellipsis) > p_length or l_max_length = 0 then
      -- Can't replace string with ellipsis if it'll return a larger string.
      l_str := substr(l_str, 1, p_length);
    elsif not l_by_word then
      -- Truncate by length
      l_str := trim(substr(l_str, 1, l_max_length)) || p_ellipsis;
    elsif l_by_word then
      -- If string at [max string(length) - ellipsis] and next characters belong to same word
      -- Then need to go back and find last non-word
      if regexp_instr(l_str, '\w{2,}', l_max_length, 1, 0) = l_max_length then
        l_str := substr(
            l_str,
            1,
            -- Find the last non-word and go back one character
            regexp_instr(substr(l_str,1, p_length - length(p_ellipsis)), '\W+\w*$') -1);

        if l_str is null then
          -- This will happen if the length is just slightly greater than the elipsis and first word is long
          l_str := substr(trim(p_str), 1, l_max_length);
        end if;

      else
        -- Find last non-word. Need to reverse the string since Oracle regexp doesn't support lookbehind assertions
        l_str := reverse(substr(l_str,1, l_max_length));
        l_str :=
          -- Unreverse string
          reverse(
            -- Cut the string from the first word char to the end in the reveresed string
            -- Since this is a reversed string, the first word char, is really the last word char
            substr(l_str, regexp_instr(l_str, '\w'))
          );

      end if;

      l_str := l_str || p_ellipsis;

      -- end l_by_word
    end if;

    return l_str;
  end truncate;

  /**
   * Does string replacement similar to C's sprintf
   *
   * Notes:
   *  - Uses the following replacement algorithm (in following order)
   *    - Replaces `%s<n>` with `p_s<n>`
   *    - Occurrences of `%s` (no number) are replaced with `p_s1..p_s10` in order that they appear in text
   *    - `%%` is escaped to `%`
   *
   * @example
   * select oos_util_string.sprintf('hello %s', 'martin') demo
   * from dual;
   *
   * DEMO
   * ------------------------------
   * hello martin
   *
   * select oos_util_string.sprintf('%s2, %s1', 'Firstname', 'Lastname') demo
   * from dual;
   *
   * DEMO
   * ------------------------------
   * Lastname, Firstname
   *
   * @issue #8
   *
   * @author Martin D'Souza
   * @created 15-Jun-2014
   * @param p_str Messsage to format using %s and %d replacement strings
   * @param p_s1..10 Replacement strings
   * @return p_msg with strings replaced
   */
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
    return varchar2
  as
    l_return varchar2(4000);
    c_substring_regexp constant varchar2(10) := '%s';

  begin
    l_return := p_str;

    -- Replace %s<n> with p_s<n>
    -- #23: Need to do in reverse so 10 processes before 1
    for i in reverse 1..10 loop
      l_return := regexp_replace(l_return, c_substring_regexp || i,
        case
          when i = 1 then p_s1
          when i = 2 then p_s2
          when i = 3 then p_s3
          when i = 4 then p_s4
          when i = 5 then p_s5
          when i = 6 then p_s6
          when i = 7 then p_s7
          when i = 8 then p_s8
          when i = 9 then p_s9
          when i = 10 then p_s10
          else null
        end,
        1,0,'c');
    end loop;

    -- Replace any occurences of %s with p_s<n> (in order) and escape %% to %
    l_return := sys.utl_lms.format_message(l_return,p_s1, p_s2, p_s3, p_s4, p_s5, p_s6, p_s7, p_s8, p_s9, p_s10);

    return l_return;

  end sprintf;


  /**
   * Converts delimited string to array
   *
   * Notes:
   *  - Similar to `apex_util.string_to_table` but handles clobs
   *
   * @issue #32
   *
   * @example
   * declare
   *   l_str clob := 'abc,def,ghi';
   *   l_arr oos_util.tab_vc2_arr;
   * begin
   *   l_arr := oos_util_string.string_to_table(p_str => l_str);
   *
   *   for i in 1..l_arr.count loop
   *     dbms_output.put_line('i: ' || i || ' ' || l_arr(i));
   *   end loop;
   * end;
   * /
   *
   * i: 1 abc
   * i: 2 def
   * i: 3 ghi
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String containing delimited text
   * @param p_delim Delimiter
   * @return Array of string
   */
  function string_to_table(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr
  is
    l_last_pos pls_integer;
    l_pos pls_integer;

    l_return oos_util.tab_vc2_arr;
    l_delimiter_len pls_integer := length(p_delim);

  begin

    if p_str is not null then
      l_last_pos := 1 - l_delimiter_len; -- If the delimeter length = 1 (most cases) this should be 0. If not need to move back "n" chars
      l_pos := 0;

      while true loop
        l_pos := l_pos + 1;
        l_pos := dbms_lob.instr(p_str, p_delim, l_pos, 1);

        if l_pos = 0 then
          l_return(l_return.count + 1) := substr(p_str, l_last_pos + l_delimiter_len); -- Get everything to the end.
          exit;
        else
          l_return(l_return.count + 1) := dbms_lob.substr(p_str, l_pos - (l_last_pos+l_delimiter_len), l_last_pos + l_delimiter_len);
        end if; -- l_pos = 0

        l_last_pos := l_pos;
      end loop;
    end if; -- p_str is not null

    return l_return;
  end string_to_table;

  /**
   * See `string_to_table (p_str clob)` for notes
   *
   * @issue  #32
   *
   * @example
   * -- See previous example
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String containing delimited text
   * @param p_delim Delimiter
   * @return Array of string
   */
  function string_to_table(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr
  is
    l_clob clob;
    l_return oos_util.tab_vc2_arr;
  begin
    l_clob := p_str;
    return string_to_table(p_str => l_clob, p_delim => p_delim);
  end string_to_table;


  /**
   * Converts delimited string to queriable table
   *
   * Notes:
   *  - Text between delimiters must be `<= 4000` characters
   *
   * @example
   *  select rownum, column_value
   *  from table(oos_util_string.listunagg('abc,def'));
   *
   *      ROWNUM COLUMN_VAL
   * ---------- ----------
   *          1 abc
   *          2 def
   *
   * @issue #4
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String containing delimited text
   * @param p_delim Delimiter
   * @return pipelined table
   */
  function listunagg(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined
  is
    l_arr oos_util.tab_vc2_arr;
  begin
    l_arr := string_to_table(p_str => p_str, p_delim => p_delim);

    for i in 1 .. l_arr.count loop
      pipe row (l_arr(i));
    end loop;
  end listunagg;


  /**
   * Converts delimited string to queriable table
   *
   * @issue #4
   *
   * @example
   * See previous example
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String (clob) containing delimited text
   * @param p_delim Delimiter
   * @return pipelined table
   */
  function listunagg(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined
  is
    l_arr oos_util.tab_vc2_arr;
  begin
    l_arr := string_to_table(p_str => p_str, p_delim => p_delim);

    for i in 1 .. l_arr.count loop
      pipe row (l_arr(i));
    end loop;
  end listunagg;


  /**
   * Returns the input string in its reverse order
   *
   * @issue #55
   *
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.reverse('OraOpenSource'));
   * end;
   * /
   *
   * ecruoSnepOarO
   *
   * @author Tim Nanos
   * @created 31-Mar-2016
   * @param p_str String
   * @return String
   */
  function reverse(
    p_str in varchar2)
    return varchar2
  is
    l_string varchar2(32767);
  begin
    if p_str is not null then
      for i in 1..length(p_str) loop
        l_string := substr(p_str, i, 1) || l_string;
      end loop;
    end if;

    return l_string;
  end reverse;

  /**
   * Returns the input number with the ordinal attached, in english.
   * e.g. 1st, 2nd, 3rd, 4th, etc
   *
   * Notes:
   * - Logic taken from: http://stackoverflow.com/a/13627586/3476713
   *
   * @issue #53
   *
   * @example
   * select oos_util_string.ordinal(level)
   * from dual
   * connect by level <= 10;
   *
   * @author Trent Schafer
   * @created 1-Aug-2016
   * @param p_num Number
   * @return String
   */
  function ordinal(
    p_num in number)
    return varchar2
  is
    l_mod10 number;
    l_mod100 number;

    l_ordinal varchar2(2);
  begin
    l_mod10 := mod(p_num, 10);
    l_mod100 := mod(p_num, 100);

    if l_mod10 = 1 and l_mod100 != 11
    then
      l_ordinal := 'st';
    elsif l_mod10 = 2 and l_mod100 != 12
    then
      l_ordinal := 'nd';
    elsif l_mod10 = 3 and l_mod100 != 13
    then
      l_ordinal := 'rd';
    else
      l_ordinal := 'th';
    end if;

    return p_num || l_ordinal;
  end ordinal;

  /**
   * Allow for multi-word replace via strings
   *
   * @issue #141
   *
   * @example
   * select multi_replace('Goodbye, universe','Goodbye,Hello,universe,world!') demo
   * from dual;
   *
   * DEMO
   * ------------------------------
   * Hello, world!
   *
   * @author Zach Wilcox
   * @created 13-Jul-2017
   * @param p_str String
   * @param p_search_str oos_util.tab_vc2
   * @param p_replace_str oos_util.tab_vc2
   * @param p_delim Delimiter default ","
   * @return String
   */
   function multi_replace(
     p_test_str in varchar2,
     p_search_str in oos_util.tab_vc2,
     p_replace_str in oos_util.tab_vc2,
     p_delim in varchar2 default ',')
     return varchar2
   as
     l_return varchar2(32767);
     l_search_arr oos_util.tab_vc2;
     l_replace_arr oos_util.tab_vc2;
   begin
     if p_replace_str is null then
         return p_test_str;
     end if;
     l_return := p_test_str;
     l_search_arr := p_search_str;
     l_replace_arr := p_replace_str;
     for i in 1..(l_replace_arr.count) loop
         l_return := replace(l_return,l_search_arr(i),l_replace_arr(i));
     end loop;
     return l_return;
 end multi_replace;

end oos_util_string;
/
