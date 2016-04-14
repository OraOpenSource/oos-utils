create or replace package oos_util_bit
as

  function bitand(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitxor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitnot(
    p_x in binary_integer)
    return binary_integer;

end;
/
