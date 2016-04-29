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
   * oos_util.assert(1=2, 'this assertion did not pass');
   *
   * -- Results in
   *
   * Error starting at line : 1 in command -
   * exec oos_util.assert(1=2, 'this assertion did not pass')
   * Error report -
   * ORA-06550: line 1, column 7:
   * PLS-00306: wrong number or types of arguments in call to 'ASSERT'
   * ORA-06550: line 1, column 7:
   * PL/SQL: Statement ignored
   * 06550. 00000 -  "line %s, column %s:\n%s"
   * *Cause:    Usually a PL/SQL compilation error.
   * *Action:

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



end oos_util;
/
