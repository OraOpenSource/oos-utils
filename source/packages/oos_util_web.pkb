create or replace package body oos_util_web
as

  -- CONSTANTS

  /**
   * Returns the mime-type for a filename
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #27
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_filename Filename
   * @return mime-type
   */
  function get_mime_type(
    p_filename in varchar2)
    return oos_util_values.value%type
  as
    l_return oos_util_values.value%type;
    l_file_ext varchar2(10);
  begin

    l_file_ext := lower(trim(leading '.' from regexp_substr(p_filename,'\.[^\.]*$')));

    begin
      select value
      into l_return
      from oos_util_values ouv
      where 1=1
        and ouv.cat = oos_util.gc_vals_cat_mime_type
        and ouv.name = l_file_ext;

    exception
      when no_data_found then
       l_return := 'application/octet';
    end;

    return l_return;


    --   select lower(extension) as extension, mime_type
    --   from xmltable (
    --      xmlnamespaces (default 'http://xmlns.oracle.com/xdb/xdbconfig.xsd'),
    --      '//mime-mappings/mime-mapping'
    --     passing xdb.dbms_xdb.cfg_get()
    --      columns
    --       extension varchar2(30) path 'extension',
    --       mime_type varchar2(80) path 'mime-type')
    --   where lower(extension) = TODO regexp;


  end get_mime_type;


  /**
   * Download file
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #2
   *  - #47: cache support
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @example
   *  ```plsql
   *    select todo from dual
   *    where 1=1
   *    from dual
   *  ```
   * @param {number=} p_filename Filename
   * @param p_mime_type mime-type of file. If null will be resolved via p_filename
   * @param p_content_disposition inline or attachment
   * @param p_cache_control options to pass to the Cache-Control attribute. Examples include max-age=3600, no-cache, etc. See https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=en for examples
   * @param p_blob File to be downloaded
   */
  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_blob in blob
    )
  as

    l_mime_type varchar2(255);
    l_blob blob := p_blob; -- Need to use l_blob since download is an in out for wpg_docload

  begin

    l_mime_type := coalesce(p_mime_type,oos_util_web.get_mime_type(p_filename => p_filename));

    -- Set Header
    sys.owa_util.mime_header(
      ccontent_type => l_mime_type,
      bclose_header => false );

    sys.htp.p('Content-length: ' || dbms_lob.getlength(p_blob));

    sys.htp.p(
      oos_util_string.sprintf(
        'Content-Disposition: %s; filename="%s"',
        p_content_disposition,
        p_filename));

    if p_cache_control is not null then
      sys.htp.p(oos_util_string.sprintf('Cache-Control: %s', p_cache_control));
    end if;

    sys.owa_util.http_header_close;

    -- download the BLOB
    sys.wpg_docload.download_file(p_blob => l_blob);

    apex_application.stop_apex_engine;
  end download_file;


  /**
   * Download clob file
   *
   * Notes:
   *  - See download_file (blob) for full documentation
   *
   * Related Tickets:
   *  - #2
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_filename
   * @param p_mime_type
   * @param p_content_disposition
   * @param p_cache_control See download_file (blob) for documentation
   * @param p_clob
   */
  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_clob in clob)
  as
    l_blob blob;
  begin

    l_blob := oos_util_lob.clob2blob(p_clob);

    download_file(
      p_filename => p_filename,
      p_mime_type => p_mime_type,
      p_content_disposition => p_content_disposition,
      p_cache_control => p_cache_control,
      p_blob => l_blob);
  end download_file;


end oos_util_web;
/
