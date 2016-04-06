create or replace package oos_util_bit
as

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
