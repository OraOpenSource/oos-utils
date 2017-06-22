create or replace package body oos_util_totp
as
  /**
   * A PL/SQL implementation of the Google Authnticator's Time-based One-Time
   * Password algorithm. The code in this package is based on the work [1] by
   * "Rabbit" from ATEX Media Solutions Pty Ltd. For more information about
   * Google Authenticator, please see reference [2].
   *
   * [1] - <https://community.oracle.com/thread/3905510>
   * [2] - <https://github.com/google/google-authenticator/wiki>
   *
   * @issue 108
   *
   * @author Adrian Png
   * @created 17-Aug-2016
   *
   */

  gc_base32 constant varchar2(32) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  gc_step constant number := 30;

  function to_binary(p_num number) return varchar2
  is
    l_szbin varchar2(8);
    l_nrem number := p_num;
  begin
    if p_num = 0 then
      return '0';
    end if;

    while l_nrem > 0 loop
      l_szbin := mod(l_nrem, 2) || l_szbin;
      l_nrem := trunc(l_nrem / 2 );
    end loop;
    return l_szbin;
  end to_binary;

  /**
   * Generates a sixteen-character alphanumeric, Base32-encoded [1] string.
   *
   * [1] - <https://en.wikipedia.org/wiki/Base32>
   *
   * @example
   * select generate_secret
   * from dual;
   *
   *
   * @param p_length number
   * @return sixteen-character alphanumeric string
   */
  function generate_secret (p_length number default 16) return varchar2
  is
    l_secret varchar2(32767);
  begin
    for i in 1..p_length loop
      l_secret := l_secret || substr(gc_base32, dbms_random.value(1, (length(gc_base32) - 1)), 1);
    end loop;

    return l_secret;
  end generate_secret;

  /**
   * Returns a URI that can be used to create a QR Code for setting up a entry
   * in Google Authenticator by scanning [1]. After obtaining the URI, create
   * a QR Code to make it easier to create an entry in Google Authenticator.
   *
   * [1] - <https://github.com/google/google-authenticator/wiki/Key-Uri-Format>
   *
   * @example
   * select
   *   oos_util_totp.format_key_uri(
   *     p_label_accountname => 'adrian.png@wonderland.com'
   *     , p_label_issuer => 'Superworld'
   *     , p_secret => 'JBSWY3DPEHPK3PXP'
   *     , p_issuer => 'Superworld'
   *   )
   * from dual;
   *
   *
   * @param p_type number (currently not supported)
   * @param p_label_accountname varchar2
   * @param p_label_issuer varchar2
   * @param p_secret varchar2
   * @param p_issuer varchar2
   * @param p_algorithm varchar2 (currently not supported)
   * @param p_digits number (currently not supported)
   * @param p_counter number (currently not supported)
   * @param p_period number (currently not supported)
   * @return URI string
   */
  function format_key_uri(
    p_type number default null
    , p_label_accountname varchar2
    , p_label_issuer varchar2
    , p_secret varchar2
    , p_issuer varchar2 default null
    , p_algorithm varchar2 default null
    , p_digits number default null
    , p_counter number default null
    , p_period number default null
  ) return varchar2
  is
    l_url varchar2(32767);
    l_issuer varchar2(32767);
    l_label varchar2(32767);
  begin
    l_url := 'otpauth://#TYPE#/#LABEL#?secret=#SECRET#&issuer=#ISSUER#';

    l_label :=
      case
        when p_label_issuer is not null then '#ISSUER#:#ACCOUNTNAME#'
        else '#ACCOUNTNAME#'
      end;

    -- Set the issuer. Only use either issue supplied. Remove  illegal characters;
    l_issuer := regexp_replace(coalesce(p_label_issuer, p_issuer), ':|;', '');

    l_label := replace(l_label, '#ISSUER#', l_issuer);
    l_label := replace(l_label, '#ACCOUNTNAME#', p_label_accountname);

    l_url := replace(l_url, '#TYPE#', 'totp');
    l_url := replace(l_url, '#LABEL#', utl_url.escape(url => l_label));
    l_url := replace(l_url, '#SECRET#', p_secret);
    l_url := replace(l_url, '#ISSUER#', utl_url.escape(url => l_issuer));

    return l_url;
  end format_key_uri;

  /**
   * Generates a six-digit number
   *
   * @todo Support for SHA-2 for Oracle 12c compilation.
   * @todo Pass MAC type as a parameter.
   *
   * @example
   * select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP')
   * from dual;
   *
   * select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP', p_offset => -30)
   * from dual;
   *
   *
   * @param p_secret varchar2
   * @param p_offset number
   * @return six-digit number as a string
   */
  function generate_otp(p_secret varchar2, p_offset number default 0) return varchar2
  is
    l_szbits varchar2(500);
    l_sztmp varchar2(500);
    l_sztmp2 varchar2(500);
    l_npos number;
    l_nepoch number(38);
    l_szepoch varchar2(16);
    l_rhmac raw(100);
    l_noffset number;
    l_npart1 number;
    l_npart2 number := 2147483647;
    l_current_timestamp timestamp with local time zone;
  begin
    for c in 1..length(p_secret) loop
      l_npos := instr(gc_base32, substr(p_secret, c, 1)) - 1;
      l_szbits := l_szbits || lpad(to_binary(l_npos), 5, '0');
    end loop;

    l_npos := 1;

    while l_npos < length(l_szbits) loop
      select
        ltrim(
          to_char(
            bin_to_num(
              to_number(substr(l_szbits, l_npos, 1))
              , to_number(substr(l_szbits, l_npos + 1, 1))
              , to_number(substr(l_szbits, l_npos + 2, 1))
              , to_number(substr(l_szbits, l_npos + 3, 1))
            )
            , 'x'
          )
        )
      into l_sztmp2
      from dual;

      l_sztmp := l_sztmp || l_sztmp2;

      l_npos := l_npos + 4;
    end loop;

    l_current_timestamp := current_timestamp;
    l_nepoch := extract(day from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00')) * 86400
      + extract(hour from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00')) * 3600
      + extract(minute from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00')) * 60
      + extract(second from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00'))
      + p_offset;

    l_szepoch := lpad(
      ltrim(
        to_char(
          floor(l_nepoch / gc_step)
          , 'xxxxxxxxxxxxxxxx'
        )
      )
      , 16
      , '0'
    );

    -- Original code
    -- l_rhmac := dbms_crypto.mac(
    --   src => hextoraw(l_szepoch)
    --   , typ => dbms_crypto.hmac_sh1
    --   , key => hextoraw(l_sztmp)
    -- );
    l_rhmac := oos_util_crypto.mac(
      p_src => hextoraw(l_szepoch)
      , p_typ => oos_util_crypto.gc_hmac_sh1
      , p_key => hextoraw(l_sztmp)
    );

    l_noffset := to_number(substr(rawtohex(l_rhmac), -1, 1), 'x');

    l_npart1 := to_number(substr(rawtohex(l_rhmac), l_noffset * 2 + 1, 8), 'xxxxxxxx');

    return substr(bitand(l_npart1, l_npart2), -6, 6);
  end generate_otp;

  /**
   * Validate an OTP. The skew parameter allows for a customizable degree of
   * tolerance for clocks that are not in sync.
   *
   * @todo Support for SHA-2 for Oracle 12c compilation.
   * @todo Pass MAC type as a parameter.
   *
   * @example
   * begin
   *   if oos_util_totp.validate_otp(
   *     p_secret => 'JBSWY3DPEHPK3PXP'
   *     , p_otp => 123456
   *     , p_skew => 30
   *   ) = 1 then
   *     dbms_output.put_line('Valid');
   *   else
   *     dbms_output.put_line('Failed');
   *   end if;
   * end;
   *
   *
   * @param p_secret varchar2
   * @param p_otp number
   * @param p_skew number
   * @return number
   */
  function validate_otp(
    p_secret varchar2
    , p_otp number
    , p_skew number default 30
  ) return number
  as
    l_ticks number;
    l_offset number;
  begin
    l_ticks := floor(p_skew / gc_step);
    l_offset := -(l_ticks * gc_step);

    while(l_offset <= l_ticks * gc_step) loop
      if p_otp = generate_otp(p_secret => p_secret, p_offset => l_offset) then
        return 1;
      else
        l_offset := l_offset + gc_step;
      end if;
    end loop;

    return 0;
  end validate_otp;
end oos_util_totp;
/
