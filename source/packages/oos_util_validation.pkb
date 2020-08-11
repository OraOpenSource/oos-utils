create or replace package body oos_util_validation
as


  -- ******** PUBLIC ********

  /**
   * Checks if string is numeric
   *
   * @issue #15
   * @issue #131 Using 12cRc validation if available
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
    deterministic
  as
    l_num number;
  $if sys.dbms_db_version.ver_le_12_1 $then
    begin
      l_num := to_number(p_str);
      return true;
    exception
      when value_error then
        return false;
  $else
    -- 12.2 onwards
    begin
      return validate_conversion(p_str as number) = 1;
  $end
  end is_number;


  /**
   * Checks if string is a valid date
   *
   * @issue #20
   * @issue #131 Using 12cRc validation if available
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
    deterministic
  as
  
  $if sys.dbms_db_version.ver_le_12_1 $then
    l_date date;
    begin
      l_date := to_date(p_str, p_date_format);
      return true;
    exception
      when others then -- Using a when others since date format could also be invalid
        return false;
  $else
    -- 12.2 onwards
    begin
      return validate_conversion(p_str as date, p_date_format) = 1;
  $end
  end is_date;

  -- TODO mdsouza: need to overload this
  -- TODO mdsouza: But look at example in issue 145) first
  /**
   * Checks if two values are equal. 
   * Overloaded to handle all types
   * 
   * Truth Table
   *
   * A | B | Result
   * --- | --- | ---
   * `null` | `null` | `true`
   * `1` | `null` | `false`
   * `null` | `1` | `false`
   * `1` | `2` | `false`
   * `1` | `1` | `true`
   * 
   *
   * @issue 145
   *
   * @example
   *
   * set serveroutput on;
   *
   * declare
   *   l_x number;
   *   l_y number;
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_equal(1,1)));
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_equal(null,1)));
   *   -- Note: can't pass in null, null as it will error out for too many overloaded functions
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_equal(l_x,l_y)));
   * end;
   * /
   * 
   * TRUE
   * FALSE
   * TRUE
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in varchar2,
    p_valb in varchar2)
    return boolean
  as
    -- TODO mdsouza: create a yn version and then remove pragma to test 
    -- TODO mdsouza: how much faster it is
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;

  /**
   * See first `is_equal`
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in number,
    p_valb in number)
    return boolean
  as
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return 
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;
  
  /**
   * See first `is_equal`
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in date,
    p_valb in date)
    return boolean
  as
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return 
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;

  /**
   * See first `is_equal`
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in timestamp,
    p_valb in timestamp)
    return boolean
  as
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return 
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;

  /**
   * See first `is_equal`
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in timestamp with time zone,
    p_valb in timestamp with time zone)
    return boolean
  as
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return 
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;

  /**
   * See first `is_equal`
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in timestamp with local time zone,
    p_valb in timestamp with local time zone)
    return boolean
  as
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return 
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;

  /**
   * See first `is_equal`
   *
   * @author Martin D'Souza
   * @created 26-Oct-2017
   * @param p_vala
   * @param p_valb
   * @return boolean Returns true if both the same or both null
   */
  function is_equal(
    p_vala in boolean,
    p_valb in boolean)
    return boolean
  as
    $if sys.dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return 
      1=2
      or p_vala is null and p_valb is null
      or p_vala = p_valb;
  end is_equal;


end oos_util_validation;
/
