declare
  l_count PLS_INTEGER;
  l_nullable user_tab_columns.nullable%TYPE;

  type typ_required_columns is record (
    name user_tab_columns.column_name%type,
    default_val varchar2 (100));
  type typ_arr_required_columns is table of typ_required_columns index by pls_integer;
  l_required_col typ_required_columns;
  l_required_cols typ_arr_required_columns;

  type typ_tab_col is record (
    name user_tab_columns.column_name%type,
    data_type varchar2 (100));
  type typ_arr_tab_col is table of typ_tab_col index by pls_integer;
  l_new_col typ_tab_col;
  l_new_cols typ_arr_tab_col;
  l_old_col typ_tab_col;
  l_old_cols typ_arr_tab_col;

  type typ_constraint is record (
    name user_constraints.constraint_name%type,
    condition user_constraints.search_condition%type);
  type typ_tab_constraint is table of typ_constraint index by pls_integer;
  l_constraint typ_constraint;
  l_constraints typ_tab_constraint;

  type typ_index is record (
    name user_indexes.index_name%type,
    col_list varchar2(100));
  type typ_tab_index is table of typ_index index by pls_integer;
  l_index typ_index;
  l_indexes typ_tab_index;

  type typ_drop_trigger is table of varchar2(30) index by pls_integer;
  l_drop_triggers typ_drop_trigger;

  l_sql varchar2 (4000);

  c_table_name constant user_tables.table_name%type := lower('table_name');
begin
  -- Create sequence to use as PK column_name
  begin
    select count(1)
    into l_count
    from user_sequences
    where sequence_name = upper(c_table_name || '_seq');

    if l_count = 0 then
      l_sql := q'!
create sequence %table_name%_seq
  minvalue 1
  maxvalue 999999999999999999999999999
  start with 1
  increment by 1
  cache 20
!';
      l_sql := replace(l_sql, '%table_name%', c_table_name);
      execute immediate l_sql;
    end if;
  end;

  -- Create table if it doesn't exist already
  begin
    select count(1)
    into l_count
    from user_tables
    where 1=1
      and table_name = upper(c_table_name);

    if l_count = 0 then
      l_sql := q'!
create table %table_name% (
  pk number not null,
  cat varchar2(255) not null,
  name varchar2(255) not null,
  value varchar2(255) not null
)
!';
      l_sql := replace(l_sql, '%table_name%', c_table_name);
      execute immediate l_sql;
    end if;
  end;

  -- Drop all constraints before modifying table, recreate them later
  begin
    l_constraints.delete;

    select constraint_name, null
    bulk collect into l_constraints
    from user_constraints
    where 1=1
      and table_name = upper(c_table_name);

    for i in 1 .. l_constraints.count
    loop
      l_sql := q'!alter table %table_name% drop constraint %constraint_name%!';
      l_sql := replace(l_sql, '%constraint_name%', l_constraints (i).name);
      l_sql := replace(l_sql, '%table_name%', c_table_name);
      execute immediate l_sql;
    end loop;
  end;

  -- Create new columns that didn't exist in the initial rollout
  begin
    l_new_cols.delete;

    l_new_col.name := 'new_col_name';
    l_new_col.data_type := 'varchar2 (20)';
    l_new_cols (l_new_cols.count + 1) := l_new_col;

    for i in 1 .. l_new_cols.count
    loop
      select count(1)
      into l_count
      from user_tab_columns
      where 1=1
        and table_name = upper(c_table_name)
        and column_name = upper(l_new_cols (i).name);

      if l_count = 0 then
        l_sql := q'!alter table %table_name% add (%column_name% %data_type%)!';
        l_sql := replace(l_sql, '%column_name%', l_new_cols (i).name);
        l_sql := replace(l_sql, '%data_type%', l_new_cols (i).data_type);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  -- Drop old columns we no longer want
  begin
    l_old_cols.delete;

    l_old_col.name := 'old_col_name';
    l_old_col.data_type := null;
    l_old_cols (l_old_cols.count + 1) := l_old_col;

    for i in 1 .. l_old_cols.count
    loop
      select count(1)
      into l_count
      from user_tab_columns
      where 1=1
        and table_name = upper(c_table_name)
        and column_name = upper(l_old_cols (i).name);

      if l_count > 0 then
        l_sql := q'!alter table %table_name% drop column %column_name%!';
        l_sql := replace(l_sql, '%column_name%', l_old_cols (i).name);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  -- Define required columns
  begin
    l_required_cols.delete;

    l_required_col.name := 'pk';
    l_required_col.default_val := 'default %table_name%_seq.nextval';
    l_required_cols (l_required_cols.count + 1) := l_required_col;

    for i in 1 ..l_required_cols.count
    loop
      select nullable
      into l_nullable
      from user_tab_columns
      where 1=1
        and table_name = upper(c_table_name)
        and column_name = upper(l_required_cols (i).name);

      if l_nullable = 'Y' then
        -- backfill the column if it currently exists and might have a null value
        l_sql := 'update %table_name% set %column_name% = %default_val% where %column_name% is null';
        l_sql := replace(l_sql, '%column_name%', l_required_cols (i).name);
        l_sql := replace(l_sql, '%default_val%', replace(l_required_cols (i).default_val, 'default', ''));
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
        -- set not null attribute and default value
        l_sql := 'alter table %table_name% modify %column_name% %default_val% not null';
        l_sql := replace(l_sql, '%column_name%', l_required_cols (i).name);
        l_sql := replace(l_sql, '%default_val%', l_required_cols (i).default_val);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  -- Create constraints
  begin
    l_constraints.delete;

    l_constraint.name := '%table_name%_pk';
    l_constraint.condition := 'primary key (pk)';
    l_constraints (l_constraints.count + 1) := l_constraint;

    l_constraint.name := '%table_name%_uk1';
    l_constraint.condition := 'unique (cat, name)';
    l_constraints (l_constraints.count + 1) := l_constraint;

    l_constraint.name := '%table_name%_ck1';
    l_constraint.condition := 'check (name = upper(name))';
    l_constraints (l_constraints.count + 1) := l_constraint;

    for i in 1 .. l_constraints.count
    loop
      select count(1)
      into l_count
      from user_constraints
      where 1=1
        and table_name = upper(c_table_name)
        and constraint_name = upper(replace(l_constraints (i).name, '%table_name%', c_table_name));

      if l_count = 0 then
        l_sql := 'alter table %table_name% add constraint %constraint_name% %constraint_condition%';
        l_sql := replace(l_sql, '%constraint_name%', l_constraints (i).name);
        l_sql := replace(l_sql, '%constraint_condition%', l_constraints (i).condition);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  -- Create indexes
  begin
    l_indexes.delete;

    l_index.name := '%table_name%_id1';
    l_index.col_list := '(pk, cat, name)';
    l_indexes (l_indexes.count + 1) := l_index;

    for i in 1 .. l_indexes.count
    loop
      select count(1)
      into l_count
      from user_indexes
      where 1=1
        and table_name = upper(c_table_name)
        and index_name = upper(replace(l_indexes (i).name, '%table_name%', c_table_name));

      if l_count = 0 then
        l_sql := 'create index %index_name% on %table_name% %index_columns%';
        l_sql := replace(l_sql, '%index_name%', l_indexes (i).name);
        l_sql := replace(l_sql, '%index_columns%', l_indexes (i).col_list);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        dbms_output.put_line(l_sql);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  -- Drop all existing triggers
  begin
    l_drop_triggers.delete;

    select trigger_name
    bulk collect into l_drop_triggers
    from user_triggers
    where 1=1
      and table_name = upper(c_table_name);

    for i in 1 .. l_drop_triggers.count
    loop
      l_sql := 'drop trigger %trigger_name%';
      l_sql := replace(l_sql, '%trigger_name%', l_drop_triggers (i));
      execute immediate l_sql;
    end loop;
  end;

  -- Create new trigger
  begin
    l_sql := q'!
create or replace trigger biu_%table_name%
  before insert or update on %table_name%
  for each row
begin
  if INSERTING then
    null;
  elsif UPDATING then
    null;
  end if;
end;
    !';
    l_sql := replace(l_sql, '%table_name%', c_table_name);
    execute immediate l_sql;
  end;
end;
/
