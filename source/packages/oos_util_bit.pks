create or replace package oos_util_bit
as

  function bitand(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic;

  function bitor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic;

  function bitxor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic;

  function bitnot(
    p_x in binary_integer)
    return binary_integer
    deterministic;

end;
/
