create or replace package body oos_util_lob
as

  /**
   * Convers clob to blob
   *
   * @issue #12
   *
   * declare
   *   l_blob blob;
   *   l_clob clob;
   * begin
   *   l_blob := oos_util_lob.clob2blob(l_clob);
   * end;
   *
   * @author Moritz Klein (https://github.com/commi235)
   * @created 07-Sep-2015
   * @param p_clob Clob to conver to blob
   * @return blob
   */
  function clob2blob(
    p_clob in clob)
    return blob
  as
    l_blob blob;
    l_dest_offset integer := 1;
    l_src_offset integer := 1;
    l_lang_ctx integer := dbms_lob.default_lang_ctx;
    l_warning integer;
  begin
    if p_clob is null then
      return null;
    end if;

    dbms_lob.createtemporary(
      lob_loc => l_blob,
      cache => false);

    dbms_lob.converttoblob(
      dest_lob => l_blob,
      src_clob => p_clob,
      amount => dbms_lob.lobmaxsize,
      dest_offset => l_dest_offset,
      src_offset => l_src_offset,
      blob_csid => dbms_lob.default_csid,
      lang_context => l_lang_ctx,
      warning => l_warning);

    oos_util.assert(l_warning = dbms_lob.no_warning, 'failed to convert clob to blob: ' || l_warning);

    return l_blob;
  end clob2blob;

  /**
   * Converts blob to clob
   *
   * Notes:
   *  - Copied from http://stackoverflow.com/questions/12849025/convert-blob-to-clob
   *
   * @issue #1
   *
   * declare
   *   l_blob blob;
   *   l_clob clob;
   * begin
   *   l_clob := oos_util_lob.blob2clob(l_blob);
   * end;
   *
   * @author Martin D'Souza
   * @created 02-Mar-2014
   * @param p_blob blob to be converted to clob
   * @return clob
   */
  function blob2clob(
    p_blob in blob)
    return clob
  as
    l_clob clob;
    l_dest_offset integer := 1;
    l_src_offset integer := 1;
    l_lang_context integer := dbms_lob.default_lang_ctx;
    l_warning integer;
  begin
    if p_blob is null then
      return null;
    end if;

    dbms_lob.createtemporary(
      lob_loc => l_clob,
      cache => false);

    dbms_lob.converttoclob(
      dest_lob => l_clob,
      src_blob => p_blob,
      amount => dbms_lob.lobmaxsize,
      dest_offset => l_dest_offset,
      src_offset => l_src_offset,
      blob_csid => dbms_lob.default_csid,
      lang_context => l_lang_context,
      warning => l_warning);

    oos_util.assert(l_warning = dbms_lob.no_warning, 'failed to convert blob to clob: ' || l_warning);

    return l_clob;
  end blob2clob;

  /**
   * Returns human readable file size
   *
   * @issue #6
   *
   * select
   *   oos_util_lob.get_file_size(2048) "2kb",
   *   oos_util_lob.get_file_size(3145728) "3mb",
   *   oos_util_lob.get_file_size(3145728, 'kb') "3mb_kb"
   * from dual;
   *
   * 2kb        3mb        3mb_kb
   * ---------- ---------- ----------
   * 2.0 KB     3.0 MB     3,072.0 KB
   *
   * @author Martin D'Souza
   * @created 07-Sep-2015
   * @param p_file_size size of file in bytes
   * @param p_units See `gc_size_...` consants for options. If not provided, most significant one automatically chosen.
   * @return Human readable file size
   */
  function get_file_size(
    p_file_size in number,
    p_units in varchar2 default null)
    return varchar2
  as
    l_units varchar2(255);
  begin
    if p_file_size is null then
      return null;
    end if;

    -- List of formats: http://www.gnu.org/software/coreutils/manual/coreutils
    l_units := nvl(upper(p_units),
      case
        when p_file_size < gc_size_b then oos_util_lob.gc_unit_b
        when p_file_size < gc_size_kb then oos_util_lob.gc_unit_kb
        when p_file_size < gc_size_mb then oos_util_lob.gc_unit_mb
        when p_file_size < gc_size_gb then oos_util_lob.gc_unit_gb
        when p_file_size < gc_size_tb then oos_util_lob.gc_unit_tb
        when p_file_size < gc_size_pb then oos_util_lob.gc_unit_pb
        when p_file_size < gc_size_eb then oos_util_lob.gc_unit_eb
        when p_file_size < gc_size_zb then oos_util_lob.gc_unit_zb
        else
          oos_util_lob.gc_unit_yb
      end
    );

    return
      trim(
        to_char(
        round(
          case
            when l_units = oos_util_lob.gc_unit_b then p_file_size/(gc_size_b/gc_size_b)
            when l_units = oos_util_lob.gc_unit_kb then p_file_size/(gc_size_kb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_mb then p_file_size/(gc_size_mb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_gb then p_file_size/(gc_size_gb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_tb then p_file_size/(gc_size_tb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_pb then p_file_size/(gc_size_pb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_eb then p_file_size/(gc_size_eb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_zb then p_file_size/(gc_size_zb/gc_size_b)
            else
              p_file_size/(gc_size_yb/gc_size_b)
          end, 1)
        ,
        -- Number format
        '999G999G999G999G999G999G999G999G999' ||
          case
            when l_units != oos_util_lob.gc_unit_b then 'D9'
            else null
          end)
        )
      || ' ' || l_units;
  end get_file_size;

  /**
   * See get_file_size
   *
   * @author Martin D'Souza
   * @created 07-Sep-2015
   * @param p_lob
   * @param p_units
   * @return
   */
  function get_lob_size(
    p_lob in clob,
    p_units in varchar2 default null)
    return varchar2
  as
  begin
    return get_file_size(
      p_file_size => dbms_lob.getlength(p_lob),
      p_units => p_units
    );
  end get_lob_size;

  /**
   * See get_file_size
   *
   * @author Martin D'Souza
   * @created 07-Sep-2015
   * @param p_lob
   * @param p_units
   * @return
   */
  function get_lob_size(
    p_lob in blob,
    p_units in varchar2 default null)
    return varchar2
  as
  begin
    return get_file_size(
      p_file_size => dbms_lob.getlength(p_lob),
      p_units => p_units
    );
  end get_lob_size;


  /**
   * Replaces p_search with p_replace
   *
   * Oracle's replace function handles clobs but runs into 32k issues
   *
   * Notes:
   *  - Source: http://dbaora.com/ora-22828-input-pattern-or-replacement-parameters-exceed-32k-size-limit/
   *
   * @issue #29
   *
   *
   * declare
   *   l_clob clob;
   * begin
   *   l_clob := 'foo bar foo';
   *
   *   l_clob := oos_util_lob.replace_clob(
   *     p_str => l_clob,
   *     p_search => 'foo',
   *     p_replace => 'hello'
   *   );
   *
   *   dbms_output.put_line(l_clob);
   * end;
   * /
   *
   * hello bar hello
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @param p_str
   * @param p_search
   * @param p_replace
   * @return Replaced string
   */
  function replace_clob(
    p_str in clob,
    p_search in varchar2,
    p_replace in clob)
    return clob
  as
    l_pos pls_integer := 1;
    l_return clob := p_str;
  begin
    while l_pos > 0 loop
      l_pos := instr(l_return, p_search, l_pos);

      if l_pos > 0 then
        l_return := substr(l_return, 1, l_pos-1)
            || p_replace
            || substr(l_return, l_pos+length(p_search));

        -- Move forward past the replaced string
        l_pos := l_pos + length(p_replace);
      end if;

    end loop;

    return l_return;
  end replace_clob;

  /**
   *
   * Write a clob (p_text) into a file (p_filename) located in a database
   * server file system directory (p_path). p_path is an Oracle directory
   * object.
   *
   * @issue #56
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 05-Apr-2016
   * @param p_text
   * @param p_path
   * @param p_filename
   */
  procedure write_file(
    p_text in clob,
    p_path in varchar2,
    p_filename in varchar2)
  as
    l_tmp_lob blob;
  begin

    -- exit if any parameter is null
    oos_util.assert(p_text is not null, 'p_text required parameter');
    oos_util.assert(p_path is not null, 'p_path required parameter');
    oos_util.assert(p_filename is not null, 'p_filename required parameter');

    -- convert a clob to a blob
    l_tmp_lob := clob2blob(p_text);

    -- write a blob to a file
    declare
      l_lob_len pls_integer;
      l_fh utl_file.file_type;
      l_pos pls_integer := 1;
      l_buffer raw(32767);
      l_amount pls_integer := 32767;
    begin
      l_fh := utl_file.fopen(
        location => p_path,
        filename => p_filename,
        open_mode =>'wb',
        max_linesize => 32767);

      l_lob_len := dbms_lob.getlength(l_tmp_lob);

      while l_pos < l_lob_len loop
        dbms_lob.read(
          lob_loc => l_tmp_lob,
          amount => l_amount,
          offset => l_pos,
          buffer => l_buffer);

        utl_file.put_raw(
          file => l_fh,
          buffer => l_buffer,
          autoflush => false);

        l_pos := l_pos + l_amount;
      end loop;

      utl_file.fclose(l_fh);
      dbms_lob.freetemporary(l_tmp_lob);
    end;

  end write_file;

  /**
   *
   * Read a content of a file (p_filename) from a database server file system
   * directory (p_path) and return it as a temporary clob. The caller is
   * responsible to free the clob (dbms_lob.freetemporary()). p_path is an
   * Oracle directory object.
   *
   * The implementation is based on UTL_FILE so the following constraints apply:
   *
   * A line size can't exceed 32767 bytes.
   *
   * Because UTL_FILE.get_line ignores line terminator it has to be added
   * implicitly. Currently the line terminator is hardcoded to char(10)
   * (unix), so if in the original file the terminator is different then a
   * conversion will take place.
   *
   * TODO: consider DBMS_LOB.LOADCLOBFROMFILE instead.
   *
   * @issue #56
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 05-Apr-2016
   * @param p_path
   * @param p_filename
   * @return clob
   */
  function read_file(
    p_path in varchar2,
    p_filename in varchar2)
    return clob
  as
    l_fh utl_file.file_type;
    l_tmp_lob clob;
  begin
    l_fh := utl_file.fopen(
      location => p_path,
      filename => p_filename,
      open_mode => 'r',
      max_linesize => 32767);

    dbms_lob.createtemporary(
      lob_loc => l_tmp_lob,
      cache => false,
      dur => dbms_lob.session);

    declare
      c_lt constant varchar2(1) := chr(10); -- unix line terminator
      l_buf varchar2(32767);
    begin
      loop
        utl_file.get_line(l_fh, l_buf);
        dbms_lob.writeappend(l_tmp_lob, length(l_buf), l_buf);
        -- get_line ignores line terminator so it is explicitly included
        dbms_lob.writeappend(l_tmp_lob, length(c_lt), c_lt);
      end loop;
    exception
      when no_data_found then
        utl_file.fclose(l_fh);
    end;

    utl_file.fclose(l_fh);

    return l_tmp_lob;
  end read_file;

end oos_util_lob;
/
