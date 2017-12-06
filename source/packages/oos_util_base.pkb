create or replace package body oos_util_base
as
  /**
   * Converts decimal (base10) numbers to other bases
   *
   * Notes:
   *  - Based on code from Tom Kyte's blog: http://www.oracle.com/technetwork/issue-archive/2006/06-jul/o46asktom-085866.html
   *  - and @connormcd comment: https://github.com/OraOpenSource/oos-utils/issues/173#issuecomment-341342912
   *
   * @issues #67, #128
   *
   * @example
   *
   * select oos_util_base.to_base(123, 12)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_BASE(123, 12)---
   * A3
   *
   * @author Zach Hudock
   * @created 26-Jun-2017
   * @param p_int pls_integer
   * @param p_base pls_integer
   * @return string p_base-converted value of p_int
   */
  function to_base(
    p_int in pls_integer,
    p_base in pls_integer)
    return varchar2
  as
    l_str varchar2(256 char) default null;
    l_quotient pls_integer := p_int;
    l_truncated pls_integer;
    l_remainder pls_integer;
  begin
    oos_util.assert(p_int >= 0, 'p_int must be a positive number');
    oos_util.assert(round(p_int, 0) = p_int, 'p_int must be a whole number');
    oos_util.assert(p_base between 2 and 62, 'p_base must be between 2 and 62');
    if (p_base = gc_decimal) then
      l_str := sys.standard.to_char(p_int);
    elsif (p_base = gc_hex) then
      l_str := upper(trim(sys.standard.to_char(p_int, rpad('x',63,'x'))));
    else
      while l_quotient > 0 loop
        l_truncated := trunc(l_quotient / p_base);
        l_remainder := l_quotient - l_truncated * p_base;
        l_quotient := l_truncated;
        l_str := substr( gc_symbols, l_remainder+1, 1) || l_str;
      end loop;
    end if;
    return l_str;
  end to_base;

  /**
   * Converts decimal (base10) numbers to binary
   *
   * @TODO: determine if spacing should be constrained to multiples of 2, 4 or no constraints
   *
   * @issues #67, #128
   *
   * @example
   *
   * select oos_util_base.to_binary(123, 4)
   * from dual;
   *
   * OOS_UTIL_STRING.to_binary(123, 4)---
   * 0111 1011
   *
   * @author Zach Hudock
   * @created 26-Jun-2017
   * @param p_int pls_integer
   * @param p_space_every pls_integer number of chars to use for spacing binary string
   * @return string binary value of p_int
   */
  function to_binary(
    p_int in pls_integer,
    p_space_every in pls_integer default 0)
    return varchar2
  as
    l_str varchar2(320 char) default null;
  begin
    oos_util.assert(mod(p_space_every, 4) = 0, 'p_space_every must be divisible by 4');
    l_str := oos_util_base.to_base(p_int, gc_binary);
    if p_space_every > 0 then
      l_str := lpad(l_str, ceil(length(l_str) / p_space_every) * p_space_every , '0'); --left pad with 0 to nearest multiple of p_space_every
      l_str := regexp_replace(l_str, '([01]{' || p_space_every || '})', ' \1'); --replace each grouping of p_space_every chars with space + self
    end if;
    return trim(l_str);
  end to_binary;

  /**
   * Converts decimal (base10) numbers to octal (base8)
   *
   * @issues #67, #128
   *
   * @example
   *
   * select oos_util_base.to_octal(123)
   * from dual;
   *
   * OOS_UTIL_STRING.to_octal(123)---
   * 173
   *
   * @author Zach Hudock
   * @created 26-Jun-2017
   * @param p_int pls_integer
   * @return string octal value of p_int
   */
  function to_octal(
    p_int in pls_integer)
    return varchar2
  as
  begin
    return oos_util_base.to_base(p_int, gc_octal);
  end to_octal;

  /**
   * Converts decimal (base10) numbers to hexidecimal (base16)
   *
   * @issues #67, #128
   *
   * @example
   *
   * select oos_util_base.to_hex(123)
   * from dual;
   *
   * OOS_UTIL_STRING.to_hex(123)---
   * 7B
   *
   * @author Zach Hudock
   * @created 26-Jun-2017
   * @param p_int pls_integer
   * @return string hexidecimal value of p_int
   */
  function to_hex(
    p_int in pls_integer)
    return varchar2
  as
  begin
    return oos_util_base.to_base(p_int, gc_hex);
  end to_hex;

  /**
   * Converts other bases to decimal (base10) numbers
   *
   * Notes:
   *  - Based on code from Tom Kyte's blog: http://www.oracle.com/technetwork/issue-archive/2006/06-jul/o46asktom-085866.html
   *
   * @issues #67, #128
   *
   * @example
   *
   * select oos_util_base.to_number('AA', 11)
   * from dual;
   *
   * OOS_UTIL_STRING.to_number('AA', 11)---
   * 120
   *
   * @author Zach Hudock
   * @created 26-Jun-2017
   * @param p_str varchar2
   * @param p_base pls_integer
   * @return string base10 value of p_str
   */
  function to_decimal(
    p_str in varchar2,
    p_base in pls_integer)
    return pls_integer
  as
    c_str constant varchar2(256 char) := case when p_base <= 36 then upper(p_str) else p_str end;
    c_regex_bad_char constant varchar2(38 char) := '[' || substr(gc_symbols, p_base + 1) || ']';
    l_num pls_integer default 0;
  begin
    oos_util.assert(p_base between 2 and 62, 'p_base must be between 2 and 62');
    oos_util.assert(regexp_instr(c_str, c_regex_bad_char) = 0, c_str || ' contains invalid characters for Base' || p_base);
    if (p_base = gc_hex) then
      l_num := sys.standard.to_number(c_str, rpad('x',63,'x'));
    else
      for i in 1 .. length(c_str) loop
        l_num := l_num * p_base + instr(gc_symbols,substr(c_str,i,1))-1;
      end loop;
    end if;
    return l_num;
  end to_decimal;

end oos_util_base;
/
