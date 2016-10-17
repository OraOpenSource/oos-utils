create or replace package body oos_util_date
as
  /*!
   * For epoch dates use http://www.epochconverter.com/ to test
   */


  /**
   * Coverts date to Unix Epoch time
   *
   * @example
   *
   * select oos_util_date.date2epoch(sysdate)
   * from dual;
   *
   * OOS_UTIL_DATE.DATE2EPOCH(SYSDATE)
   * ---------------------------------
   *                        1461663997
   *
   * @issue #18
   *
   * @author Martin Giffy D'Souza
   * @created 30-Dec-2015
   * @param p_date Date to convert to Epoch format
   * @return Unix Epoch time
   */
  function date2epoch(
    p_date in date)
    return number
  as
    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return
      round(
        (p_date - to_date ('19700101', 'yyyymmdd')) * 86400
        - (to_number(substr (tz_offset (sessiontimezone), 1, 3))+0) * 3600); -- Note: Was +1 but was causing 1 hour behind (#123)
  end date2epoch;


  /**
   * Converts Unix linux time to Oracle date
   *
   * @issue 18
   *
   * @example
   *
   * select oos_util_date.epoch2date(1461663982)
   * from dual;
   *
   * OOS_UTIL_DATE.EPOCH2DATE(1461663982)
   * ------------------------------------
   * 26-APR-2016 12:46:22
   *
   * @author Martin Giffy D'Souza
   * @created 31-Dec-2015
   * @param p_epoch Epoch Unix date (number)
   * @return date
   */
  function epoch2date(
    p_epoch in number)
    return date
  as

  begin
    return
      to_date ('19700101', 'yyyymmdd')
      + ((p_epoch + ((to_number(substr(tz_offset(sessiontimezone), 1, 3))+0) * 3600)) / 86400); -- Note: Was +1 but was causing 1 hour ahead (#123)
  end epoch2date;
  

  /*!
   * Coverts timestamp to Unix Epoch time
   *
   * @private Currently used for crypto. Needs more testing to make puplically available.
   *
   * @example
   *
   * select oos_util_date.timestamp2epoch(current_timestamp)
   * from dual;
   *
   * OOS_UTIL_DATE.TIMESTAMP2EPOCH(CURRENT_TIMESTAMP)
   * ---------------------------------
   * 1474277938
   *
   * @author Adrian Png
   * @created 22-Sep-2016
   * @param p_timestamp Timestamp to convert to Epoch format
   * @return Unix Epoch time
   */
  function timestamp2epoch(
    p_timestamp in timestamp)
    return pls_integer
  as
    c_start_time constant  timestamp with time zone := timestamp '1970-01-01 00:00:00 +00:00';
  begin
    return extract(day from (p_timestamp - c_start_time)) * 86400
      + extract(hour from (p_timestamp - c_start_time)) * 3600
      + extract(minute from (p_timestamp - c_start_time)) * 60
      + extract(second from (p_timestamp - c_start_time))
    ;
  end timestamp2epoch;


end oos_util_date;
/
