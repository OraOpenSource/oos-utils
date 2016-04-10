create or replace package body oos_util_bit
as

  /**
   * Bit OR
   *
   * Copied from http://www.orafaq.com/wiki/Bit
   *
   * The function signature is similar to PL/SQL version of Oracle native
   * implemented bitand: https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param x binary_integer
   * @param y binary_integer
   * @return binary_integer
   */
  function bitor(
    x in binary_integer,
    y in binary_integer)
    return binary_integer
  as
  begin
    return x + y - bitand(x, y);
  end;

  /**
   * Bit XOR
   *
   * Copied from http://www.orafaq.com/wiki/Bit
   *
   * The function signature is similar to PL/SQL version of Oracle native
   * implemented bitand: https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param x binary_integer
   * @param y binary_integer
   * @return binary_integer
   */
  function bitxor(
    x in binary_integer,
    y in binary_integer)
    return binary_integer
  as
  begin
    return bitor(x, y) - bitand(x, y);
  end;

  /**
   * Bit NOT
   *
   * Copied from http://www.orafaq.com/wiki/Bit
   *
   * The function signature is similar to PL/SQL version of Oracle native
   * implemented bitand: https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param x binary_integer
   * @return binary_integer
   */
  function bitnot(
    x in binary_integer)
    return binary_integer
  as
  begin
    return (0 - x) - 1;
  end;

end;
/