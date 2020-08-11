create or replace package body oos_util
as
  -- CONSTANTS
  gc_assert_error_number constant pls_integer := -20000;


  -- ******** PRIVATE ********

  /*!
   * Internal logging procedure.
   * Requires Logger to be installed only while developing.
   * -- TODO mdsouza: conditional compilation notes
   *
   *
   * @author Martin D'Souza
   * @created 17-Aug-2015
   * @param p_message Item to log
   * @param p_scope Logger scope
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
   * Validates assertion.
   * Will raise an application error if assertion is false
   *
   * @example
   *
   * exec oos_util.assert(1=2, 'this assertion did not pass');
   *
   * -- Results in
   *
   * 
   * Error starting at line : 39 in command -
   * BEGIN oos_util.assert(1=2, 'this assertion did not pass'); END;
   * Error report -
   * ORA-20000: this assertion did not pass
   * ORA-06512: at "GIFFY.OOS_UTIL", line 70
   * ORA-06512: at line 1
   * 20000. 00000 -  "%s"
   *
   * @issue #19
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
   * Sleep procedure for n seconds
   *
   * Notes:
   *  - It is recommended that you use Oracle's lock procedures: http://psoug.org/reference/sleep.html
   *    - In instances where you do not have access use this sleep method instead
   *  - This implementation may tie up CPU so only use for development purposes
   *  - This is a custom implementation of sleep and as a result the times are not 100% accurate
   *  - If calling in SQLDeveloper may get "IO Error: Socket read timed out". This is a JDBC driver setting, not a bug in this code.
   *
   * @issue #13
   *
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(sysdate));
   *   oos_util.sleep(5);
   *   dbms_output.put_line(oos_util_string.to_char(sysdate));
   * end;
   * /
   *
   * 26-APR-2016 14:29:02
   * 26-APR-2016 14:29:07
   *
   * @author Martin Giffy D'Souza
   * @created 31-Dec-2015
   * @param p_seconds Number of seconds to sleep for
   */
  procedure sleep(
    p_seconds in simple_integer)
  as
    l_now timestamp := systimestamp;
    l_end_time timestamp;

  begin
    l_end_time := l_now + numtodsinterval (p_seconds, 'second');

    -- Note: Can't use systimestamp in loop since it doesn't seem to calculate a new timestamp each iteration.
    while(l_end_time > l_now) loop
      l_now := systimestamp;
    end loop;
  end sleep;



  /**
   * **TODO**: This will probably be renamed in final 1.1.0 release
   *
   * Converts an Associated Array to Nested Table
   * See https://oracle-base.com/articles/8i/collections-8i for different array types and how to leverage Nested Tables for things like Multiset and Member functions.
   *
   * @example
   * declare
   *   -- Associative Arrays
   *   l_arr1 oos_util.tab_vc2_arr;
   *   l_arr2 oos_util.tab_vc2_arr;
   *
   *   -- Nested Tables
   *   l_nt1 oos_util.tab_vc2;
   *   l_nt2 oos_util.tab_vc2;
   *   l_result oos_util.tab_vc2;
   * begin
   *   l_arr1(1) := 'abc';
   *   l_arr1(2) := 'def';
   *   l_arr2(1) := 'ghi';
   *
   *   l_nt1 := oos_util.assoc_arr2nested_table(l_arr1);
   *   l_nt2 := oos_util.assoc_arr2nested_table(l_arr2);
   *
   *   dbms_output.put_line('*Multiset Union*');
   *   l_result := l_nt1 multiset union l_nt2;
   *   for i in 1..l_result.count loop
   *     dbms_output.put_line(l_result(i));
   *   end loop;
   *   dbms_output.put_line('');
   *
   *   dbms_output.put_line('*Subset*');
   *   dbms_output.put_line(oos_util_string.to_char(l_nt1 submultiset of l_nt2));
   *   dbms_output.put_line('');
   *
   *   dbms_output.put_line('*Member Of*');
   *   dbms_output.put_line(oos_util_string.to_char('def' member of l_nt1));
   *
   * end;
   * /
   *
   * *Multiset Union*
   * abc
   * def
   * ghi
   *
   * *Subset*
   * FALSE
   *
   * *Member Of*
   * TRUE
   *
   * PL/SQL procedure successfully completed.
   *
   * @issue #110
   *
   * @author Martin D'Souza
   * @created 15-Jul-2017
   * @param p_assoc_arr Associated Array(vc2) to be converted to Nested Table
   * @return Nested Table (vc2)
   */
  function assoc_arr2nested_table(
    p_assoc_arr in oos_util.tab_vc2_arr)
    return oos_util.tab_vc2
  as
    l_return oos_util.tab_vc2 := oos_util.tab_vc2();
    l_cnt pls_integer := 0;
  begin
    -- TODO mdsouza: better name and update docs above
    l_return.extend(p_assoc_arr.count);
    for i in p_assoc_arr.first .. p_assoc_arr.last loop
      l_cnt := l_cnt + 1;

      l_return(l_cnt) := p_assoc_arr(i);
    end loop;

    return l_return;
  end assoc_arr2nested_table;

  /**
   * See previous function for details and examples.
   * This is an overloaded function for number table
   *
   * @issue $110
   *
   * @author Martin D'Souza
   * @created 16-Jul-2017
   * @param p_assoc_arr p_assoc_arr Associated Array(num) to be converted to Nested Table
   * @return Nested Table (num)
   */
  function assoc_arr2nested_table(
    p_assoc_arr in oos_util.tab_num_arr)
    return oos_util.tab_num
  as
    l_return oos_util.tab_num := oos_util.tab_num();
    l_cnt pls_integer := 0;
  begin
    l_return.extend(p_assoc_arr.count);

    for i in p_assoc_arr.first .. p_assoc_arr.last loop
      l_cnt := l_cnt + 1;
      l_return(l_cnt) := p_assoc_arr(i);
    end loop;

    return l_return;
  end assoc_arr2nested_table;

end oos_util;
/
