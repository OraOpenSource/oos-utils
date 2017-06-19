create or replace package body oos_util_bit
as

  /**
   * [bitwise AND](https://en.wikipedia.org/wiki/Bitwise_operation#AND)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitand(1,3)
   * from dual;
   *
   * OOS_UTIL_BIT.BITAND(1,3)
   * ------------------------
   *                       1
   *
   * @issue #69
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-Apr-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitand(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic
  as
  begin
    return sys.standard.bitand(p_x, p_y);
  end bitand;

  /**
   * [bitwise OR](https://en.wikipedia.org/wiki/Bitwise_operation#OR)
   *
   * Copied from [http://www.orafaq.com/wiki/Bit](http://www.orafaq.com/wiki/Bit)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitor(1,3)
   * from dual;
   *
   * OOS_UTIL_BIT.BITOR(1,3)
   * -----------------------
   *                       3
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic
  as
  begin
    return p_x + p_y - bitand(p_x, p_y);
  end bitor;

  /**
   * [bitwise XOR](https://en.wikipedia.org/wiki/Bitwise_operation#XOR)
   *
   * Copied from [http://www.orafaq.com/wiki/Bit](http://www.orafaq.com/wiki/Bit)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitxor(1,3)
   * from dual;
   *
   * OOS_UTIL_BIT.BITXOR(1,3)
   * ------------------------
   *                        2
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitxor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic
  as
  begin
    return bitor(p_x, p_y) - bitand(p_x, p_y);
  end bitxor;

  /**
   * [bitwise NOT](https://en.wikipedia.org/wiki/Bitwise_operation#NOT)
   *
   * Copied from [http://www.orafaq.com/wiki/Bit](http://www.orafaq.com/wiki/Bit)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitnot(7)
   * from dual;
   *
   * OOS_UTIL_BIT.BITNOT(7)
   * ----------------------
   *                     -8
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param p_x binary_integer
   * @return binary_integer
   */
  function bitnot(
    p_x in binary_integer)
    return binary_integer
    deterministic
  as
  begin
    return (0 - p_x) - 1;
  end bitnot;


  /**
   * From [https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Left_shift](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Left_shift): _This operator shifts the first operand the specified number of bits to the left. Excess bits shifted off to the left are discarded. Zero bits are shifted in from the right_.
   *
   * @example
   *
   * select oos_util_bit.bitshift_left(7, 4)
   * from dual;
   *
   * OOS_UTIL_BIT.BITSHIFT_LEFT(7,4)
   * 112
   *
   * -- In binary terms this converted 111 (7) to 1110000 (112)
   *
   * @issue #112
   *
   * @author Anton Scheffer
   * @created 22-Sep-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitshift_left(
    p_x binary_integer,
    p_y binary_integer)
    return binary_integer
    deterministic
  is
  begin
    return p_x * power(2, p_y);
  end bitshift_left;

  /**
   * From [https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Right_shift](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Right_shift): _This operator shifts the first operand the specified number of bits to the right. Excess bits shifted off to the right are discarded. Copies of the leftmost bit are shifted in from the left. Since the new leftmost bit has the same value as the previous leftmost bit, the sign bit (the leftmost bit) does not change. Hence the name "sign-propagating"._
   *
   * @example
   *
   * select oos_util_bit.bitshift_right(7, 1)
   * from dual;
   *
   * OOS_UTIL_BIT.BITSHIFT_RIGHT(7,1)
   * 3
   *
   * -- In binary terms this converted 111 (7) to 011 (3)
   *
   * @issue #112
   *
   * @author Anton Scheffer
   * @created 22-Sep-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitshift_right(
    p_x binary_integer,
    p_y binary_integer)
    return binary_integer
    deterministic
  is
  begin
    return trunc(p_x / power(2, p_y));
  end bitshift_right;

end;
/
