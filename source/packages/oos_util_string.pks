create or replace package oos_util_string
as

  function tochar(
    p_val in number)
    return varchar2;

  function tochar(
    p_val in date)
    return varchar2;

  function tochar(
    p_val in timestamp)
    return varchar2;

  function tochar(
    p_val in timestamp with time zone)
    return varchar2;

  function tochar(
    p_val in timestamp with local time zone)
    return varchar2;

  function tochar(
    p_val in boolean)
    return varchar2;

  function truncate_string(
    p_str in varchar2,
    p_length in pls_integer,
    p_by_word in varchar2 default 'N')
    return varchar2;

end oos_util_string;
/
