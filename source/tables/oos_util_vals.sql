declare
  l_count pls_integer;
  l_table_name user_tables.table_name%type;
  l_sql varchar2(4000);
begin
  l_table_name := lower('oos_util_vals');

  select count(1)
  into l_count
  from user_tables
  where 1=1
    and table_name = upper(l_table_name);

  if l_count = 0 then
    l_sql := 'create table %table_name% (
  cat varchar2(255) not null,
  name varchar2(255) not null,
  value varchar2(255) not null,
  constraint %table_name%_uk1 unique (cat,name)
)';
    l_sql := replace(l_sql, '%table_name%', l_table_name);

  end if;

  if l_sql is not null then
    execute immediate l_sql;
  end if;

end;
/
