set pagesize 9999
set linesize 9999
set heading off
set trim on
-- set verify off

select lower(attribute) -- error or warning
  || ' '
  || line || '/' || position -- line and column
  || ' '
  || lower(name) -- file name
  || case -- file extension
    when type = 'PACKAGE' then '.pks'
    when type = 'PACKAGE BODY' then '.pkb'
    else '.sql'
  end
  || ' '
  || replace(text, chr(10), ' ') -- remove line breaks from error text
  as user_errors
from user_errors
where attribute in ('ERROR', 'WARNING')
  and name = upper(substr('&&1',1, length('&&1')-4))
order by type, name, line, position;