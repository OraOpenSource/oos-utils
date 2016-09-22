declare
  c_table_name constant user_tables.table_name%type := lower('table_name');

  c_drop_triggers constant boolean := false; -- this will drop all triggers associated to the table
  c_drop_constraints constant boolean := false; -- this will drop all constraints associated to the table
  c_create_sequence constant boolean := false; -- this will create a sequence to be used as the primary key for the table

  c_table_sql constant varchar2 (2000) := q'!
create table %table_name% (
  pk number not null,
  cat varchar2(255) not null,
  name varchar2(255) not null,
  value varchar2(255) not null
)
!';

  c_trigger_sql constant varchar2 (200) := q'!
create or replace trigger %trigger_name%
%trigger_type% %trigger_event% on %table_name%
for each row
%trigger_body%
!';

  c_sequence_sql constant varchar2 (200) := q'!
create sequence %table_name%_seq
  minvalue 1
  maxvalue 999999999999999999999999999
  start with 1
  increment by 1
  cache 20
!';

  c_add_column_sql constant varchar2 (100) := 'alter table %table_name% add (%column_name% %data_type%)';
  c_drop_column_sql constant varchar2 (100) := 'alter table %table_name% drop column %column_name%';
  c_backfill_required_sql constant varchar2 (100) := 'update %table_name% set %column_name% = %default_val% where %column_name% is null';
  c_required_column_sql constant varchar2 (100) := 'alter table %table_name% modify %column_name% %default_val% not null';
  c_add_constraint_sql constant varchar2 (100) := 'alter table %table_name% add constraint %constraint_name% %constraint_condition%';
  c_drop_constraint_sql constant varchar2 (100) := 'alter table %table_name% drop constraint %constraint_name%';
  c_create_index_sql constant varchar2 (100) := 'create index %index_name% on %table_name% %index_columns%';
  c_drop_trigger_sql constant varchar2 (100) := 'drop trigger %trigger_name%';

  l_sql varchar2 (4000);
  l_count pls_integer;
  l_nullable user_tab_columns.nullable%type;

  type typ_tab_col is record (
    name user_tab_columns.column_name%type,
    data_type varchar2 (100),
    default_val varchar2 (100));
  type typ_arr_tab_col is table of typ_tab_col index by pls_integer;
  l_column typ_tab_col;
  l_columns typ_arr_tab_col;

  type typ_constraint is record (
    name user_constraints.constraint_name%type,
    condition user_constraints.search_condition_vc%type);
  type typ_tab_constraint is table of typ_constraint index by pls_integer;
  l_constraint typ_constraint;
  l_constraints typ_tab_constraint;

  type typ_index is record (
    name user_indexes.index_name%type,
    col_list varchar2(200));
  type typ_tab_index is table of typ_index index by pls_integer;
  l_index typ_index;
  l_indexes typ_tab_index;

  type typ_trigger is record (
    name user_triggers.trigger_name%type,
    trigger_type user_triggers.trigger_type%type,
    trigger_event user_triggers.triggering_event%type,
    trigger_body user_triggers.trigger_body%type);
  type typ_tab_trigger is table of typ_trigger index by pls_integer;
  l_trigger typ_trigger;
  l_triggers typ_tab_trigger;

  type typ_drop_object is table of varchar2(30) index by pls_integer;
  l_drop_objects typ_drop_object;
begin

  /**
   * Create table if it doesn't already exist
   */
  begin
    select count(1)
    into l_count
    from user_tables
    where 1=1
      and table_name = upper(c_table_name);

    if l_count = 0 then
      l_sql := c_table_sql;
      l_sql := replace(l_sql, '%table_name%', c_table_name);
      execute immediate l_sql;
    end if;
  end;

  /**
   * Create new columns that didn't exist in the initial table creation
   *
   * @example
   * l_column.name := 'new_col_1';
   * l_column.data_type := 'varchar2 (20)';
   * l_columns (l_columns.count + 1) := l_column;
   *
   * l_column.name := 'new_col_2';
   * l_column.data_type := 'date';
   * l_columns (l_columns.count + 1) := l_column;
   */
  begin
    l_columns.delete;

    /* TODO: l_column setup goes here */

    for i in 1 .. l_columns.count
    loop
      select count(1)
      into l_count
      from user_tab_columns
      where 1=1
        and table_name = upper(c_table_name)
        and column_name = upper(l_columns (i).name);

      if l_count = 0 then
        l_sql := c_add_column_sql;
        l_sql := replace(l_sql, '%column_name%', l_columns (i).name);
        l_sql := replace(l_sql, '%data_type%', l_columns (i).data_type);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  /**
   * Drop columns that are no longer needed but were in the initial table creation
   *
   * @example
   * l_column.name := 'new_col_1';
   * l_columns (l_columns.count + 1) := l_column;
   */
  begin
    l_columns.delete;

    /* TODO: l_column setup goes here */

    for i in 1 .. l_columns.count
    loop
      select count(1)
      into l_count
      from user_tab_columns
      where 1=1
        and table_name = upper(c_table_name)
        and column_name = upper(l_columns (i).name);

      if l_count > 0 then
        l_sql := c_drop_column_sql;
        l_sql := replace(l_sql, '%column_name%', l_columns (i).name);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  /**
   * Create sequence to use as an ID column if c_create_sequence flag is set
   */
  if c_create_sequence = true then
    begin
      select count(1)
      into l_count
      from user_sequences
      where sequence_name = upper(c_table_name || '_seq');

      if l_count = 0 then
        l_sql := c_sequence_sql;
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end;
  end if;

  /**
   * Drop all constraints from table if c_drop_constraints flag is set
   */
  if c_drop_constraints = true then
    begin
      l_drop_objects.delete;

      select constraint_name
      bulk collect into l_drop_objects
      from user_constraints
      where 1=1
        and table_name = upper(c_table_name);

      for i in 1 .. l_drop_objects.count
      loop
        l_sql := c_drop_constraint_sql;
        l_sql := replace(l_sql, '%constraint_name%', l_drop_objects(i));
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end loop;
    end;
  end if;

  /**
   * Define required columns
   *
   * @example
   * l_column.name := 'pk';
   * l_column.data_type := 'default %table_name%_seq.nextval';
   * l_columns (l_columns.count + 1) := l_column;
   *
   * l_column.name := 'new_col_2';
   * l_column.data_type := 'default sysdate';
   * l_columns (l_columns.count + 1) := l_column;
   */
  begin
    l_columns.delete;

    /* TODO: l_column setup goes here */

    for i in 1 ..l_columns.count
    loop
      select nullable
      into l_nullable
      from user_tab_columns
      where 1=1
        and table_name = upper(c_table_name)
        and column_name = upper(l_columns (i).name);

      if l_nullable = 'Y' then
        -- backfill the column if it currently exists and might have a null value
        l_sql := c_backfill_required_sql;
        l_sql := replace(l_sql, '%column_name%', l_columns (i).name);
        l_sql := replace(l_sql, '%default_val%', replace(l_columns (i).default_val, 'default', ''));
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
        -- set not null attribute and default value
        l_sql := c_required_column_sql;
        l_sql := replace(l_sql, '%column_name%', l_columns (i).name);
        l_sql := replace(l_sql, '%default_val%', l_columns (i).default_val);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  /**
   * Create constraints
   *
   * @example
   * l_constraint.name := '%table_name%_pk';
   * l_constraint.condition := 'primary key (pk)';
   * l_constraints (l_constraints.count + 1) := l_constraint;
   *
   * l_constraint.name := '%table_name%_uk1';
   * l_constraint.condition := 'unique (cat, name)';
   * l_constraints (l_constraints.count + 1) := l_constraint;
   *
   * l_constraint.name := '%table_name%_ck1';
   * l_constraint.condition := 'check (name = upper(name))';
   * l_constraints (l_constraints.count + 1) := l_constraint;
   */
  begin
    l_constraints.delete;

    /* TODO: l_constraint setup goes here */

    for i in 1 .. l_constraints.count
    loop
      select count(1)
      into l_count
      from user_constraints
      where 1=1
        and table_name = upper(c_table_name)
        and constraint_name = upper(replace(l_constraints (i).name, '%table_name%', c_table_name));

      if l_count = 0 then
        l_sql := c_add_constraint_sql;
        l_sql := replace(l_sql, '%constraint_name%', l_constraints (i).name);
        l_sql := replace(l_sql, '%constraint_condition%', l_constraints (i).condition);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  /**
   * Create indexes
   *
   * @example
   * l_index.name := '%table_name%_id1';
   * l_index.col_list := '(pk, cat, name)';
   * l_indexes (l_indexes.count + 1) := l_index;
   */
  begin
    l_indexes.delete;

    /* TODO: l_index setup goes here */

    for i in 1 .. l_indexes.count
    loop
      select count(1)
      into l_count
      from user_indexes
      where 1=1
        and table_name = upper(c_table_name)
        and index_name = upper(replace(l_indexes (i).name, '%table_name%', c_table_name));

      if l_count = 0 then
        l_sql := c_create_index_sql;
        l_sql := replace(l_sql, '%index_name%', l_indexes (i).name);
        l_sql := replace(l_sql, '%index_columns%', l_indexes (i).col_list);
        l_sql := replace(l_sql, '%table_name%', c_table_name);
        dbms_output.put_line(l_sql);
        execute immediate l_sql;
      end if;
    end loop;
  end;

  /**
   * Drop all triggers from table if c_drop_triggers flag is set
   */
  if c_drop_triggers = true then
    begin
      l_drop_objects.delete;

      select trigger_name
      bulk collect into l_drop_objects
      from user_triggers
      where 1=1
        and table_name = upper(c_table_name);

      for i in 1 .. l_drop_objects.count
      loop
        l_sql := 'drop trigger %trigger_name%';
        l_sql := replace(l_sql, '%trigger_name%', l_drop_objects (i));
        execute immediate l_sql;
      end loop;
    end;
  end if;

  /**
   * Create or replace the triggers for the table
   *
   * @example
   * l_trigger.name := 'biu_%table_name%'
   * l_trigger.trigger_type := 'before';
   * l_trigger.trigger_event := 'insert or update';
   * l_trigger.trigger_body := q'!
   * begin
   *   if INSERTING then
   *     null;
   *   elsif UPDATING then
   *     null;
   *   end if;
   *   -- ALWAYS
   *   null;
   * end;
   * !';
   * l_triggers (l_triggers.count + 1) := l_trigger;
   */
  begin
    l_triggers.delete;

    /* TODO: l_trigger setup goes here */

    for i in 1 .. l_triggers.count
    loop
      l_sql := c_trigger_sql;
      l_sql := replace(l_sql, '%trigger_name%', l_triggers (i).name);
      l_sql := replace(l_sql, '%trigger_type%', l_triggers (i).trigger_type);
      l_sql := replace(l_sql, '%trigger_event%', l_triggers (i).trigger_event);
      l_sql := replace(l_sql, '%trigger_body%', l_triggers (i).trigger_body);
      l_sql := replace(l_sql, '%table_name%', c_table_name);
      execute immediate l_sql;
    end loop;
  end;
end;
/
