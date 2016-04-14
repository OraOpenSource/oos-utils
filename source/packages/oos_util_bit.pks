create or replace package oos_util_bit
as

  function bitand(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitor(
    x in binary_integer,
    y in binary_integer)
    return binary_integer;

  function bitxor(
    x in binary_integer,
    y in binary_integer)
    return binary_integer;

  function bitnot(
    x in binary_integer)
    return binary_integer;

end;
/
