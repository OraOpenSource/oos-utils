create or replace package oos_util_lob
as
  -- CONSTANTS
  gc_unit_b constant varchar2(1) := 'B';
  gc_unit_kb constant varchar2(2) := 'KB';
  gc_unit_mb constant varchar2(2) := 'MB';
  gc_unit_gb constant varchar2(2) := 'GB';
  gc_unit_tb constant varchar2(2) := 'TB';
  gc_unit_pb constant varchar2(2) := 'PB';
  gc_unit_eb constant varchar2(2) := 'EB';
  gc_unit_zb constant varchar2(2) := 'ZB';
  gc_unit_yb constant varchar2(2) := 'YB';

  gc_size_b constant simple_integer := 1024;
  gc_size_kb constant simple_integer := power(1024, 2);
  gc_size_mb constant simple_integer := power(1024, 3);
  gc_size_gb constant simple_integer := power(1024, 4);
  gc_size_tb constant simple_integer := power(1024, 5);
  gc_size_pb constant simple_integer := power(1024, 6);
  gc_size_eb constant simple_integer := power(1024, 7);
  gc_size_zb constant simple_integer := power(1024, 8);
  gc_size_yb constant simple_integer := power(1024, 9);


  -- METHODS
  function clob2blob(
    p_clob in clob)
    return blob;

  function blob2clob(
    p_blob in blob)
    return clob;

  function get_file_size(
    p_file_size in number,
    p_units in varchar2 default null)
    return varchar2;

  function get_lob_size(
    p_lob in clob,
    p_units in varchar2 default null)
    return varchar2;

  function get_lob_size(
    p_lob in blob,
    p_units in varchar2 default null)
    return varchar2;
end oos_util_lob;
/
