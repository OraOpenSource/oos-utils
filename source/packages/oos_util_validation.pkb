create or replace package body oos_util_validation
as


  -- ******** PUBLIC ********

  /**
   * Checks if string is numeric
   *
   * @issue #15
   *
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_number('123')));
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_number('abc')));
   * end;
   * /
   *
   * TRUE
   * FALSE
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
   * @issue #20
   *
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(
   *     oos_util_validation.is_date('01-JAN-2015', 'DD-MON-YYYY')));
   *   dbms_output.put_line(oos_util_string.to_char(
   *     oos_util_validation.is_date('not-a-date', 'DD-MON-YYYY')));
   * end;
   * /
   *
   * TRUE
   * FALSE
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


end oos_util_validation;
/
