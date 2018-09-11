create or replace package oos_util_base
as
  -- TYPES

  -- CONSTANTS
  /**
   * @TODO: determine if symbols should follow pattern (digits, upper, lower) or (digits, lower, upper)
   *  [1] - https://pgregg.com/projects/php/base_conversion/base_conversion.inc.phps
   *  [2] - https://www.dcode.fr/base-n-convert
   *
   * @constant gc_symbols list of alphanumeric characters
   * @constant gc_binary 2
   * @constant gc_octal 8
   * @constant gc_decimal 10
   * @constant gc_hex 16
   */
  gc_symbols constant varchar2(62 char) := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  gc_binary constant pls_integer := 2;
  gc_octal constant pls_integer := 8;
  gc_decimal constant pls_integer := 10;
  gc_hex constant pls_integer := 16;

  -- METHODS
  function to_base(
    p_int in pls_integer,
    p_base in pls_integer,
    p_alphabet in varchar2 default gc_symbols)
    return varchar2;

  function to_binary(
    p_int in pls_integer,
    p_space_every in pls_integer default 0)
    return varchar2;

  function to_octal(
    p_int in pls_integer)
    return varchar2;

  function to_hex(
    p_int in pls_integer)
    return varchar2;

  function to_decimal(
    p_str in varchar2,
    p_base in pls_integer,
    p_alphabet in varchar2 default gc_symbols)
    return pls_integer;

end oos_util_base;
/
