create or replace package oos_util_transform as

  function refcur2xml(
    p_rc in sys_refcursor,
    p_null_handling in number default dbms_xmlgen.null_attr)
    return xmltype;

  function xml_has_rows(
    p_xml in xmltype)
    return boolean;

  function xslt(
    p_in in xmltype,
    p_trans in xmltype)
    return xmltype;

  function xquery(
    p_in in xmltype,
    p_trans in varchar2)
    return xmltype;

  function refcur2csv(
    p_rc in sys_refcursor,
    p_column_names in boolean default false,
    p_return_empty in boolean default false)
    return clob;

  function refcur2csv2(
    p_rc        in out sys_refcursor,
    p_column_names in boolean default false,
    p_separator in varchar2 default ',',
    p_endline   in varchar2 default chr(13)||chr(10),
    p_date_fmt  in varchar2 default 'YYYY-MM-DD HH24:MI:SS')
    return clob;

  function refcur2html(
    p_rc in sys_refcursor,
    p_return_empty in boolean default false)
    return clob;

  function refcur2json(
    p_rc in sys_refcursor,
    p_return_empty in boolean default false)
    return clob;

  function entity_decode(
    p_in clob)
    return clob;

end oos_util_transform;
/
