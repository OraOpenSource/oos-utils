set serveroutput on;

select oos_util_bit.bitshift_left(4,2)
from dual;

select oos_util_crypto.sha1('hello')
from dual;


select utl_raw.length(null)
from dual;

select  to_binary(2)
from dual;

-- 67452301

select current_timestamp
from dual;

declare
  l_nepoch number(38);
  l_now timestamp with local time zone;
begin
  l_now:= current_timestamp;
  
  l_nepoch := extract(day from (l_now - timestamp '1970-01-01 00:00:00 +00:00')) * 86400
    + extract(hour from (l_now - timestamp '1970-01-01 00:00:00 +00:00')) * 3600
    + extract(minute from (l_now - timestamp '1970-01-01 00:00:00 +00:00')) * 60
    + extract(second from (l_now - timestamp '1970-01-01 00:00:00 +00:00'))
    + 0;
    
  dbms_output.put_line('Adrian: ' || l_nepoch);
  dbms_output.put_line('oos_util: ' || oos_util_date.timestamp2epoch(l_now));
end;
/

declare
  l_str varchar2(16) := 'hello';
  l_rhmac raw(100);
begin
  
  l_str := lpad(l_str, 16, 0);
  
  l_rhmac := dbms_crypto.mac(
      src => hextoraw(l_str)
      , typ => dbms_crypto.hmac_sh1
      , key => hextoraw(l_sztmp)
    );
  
  dbms_output.put_line(l_str);
end;
/