create or replace package body oos_util_apex
as

  -- CONSTANTS


  /**
   * Download file
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #2
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_filename Filename
   * @param p_mime_type mime-type of file. If null will be resolved via p_filename
   * @param p_content_disposition inline or attachment
   * @param p_blob File to be downloaded
   */
  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
    p_blob in blob)
  as

    l_mime_type varchar2(255);
    l_blob blob := p_blob; -- Need to use l_blob since download is an in out

  begin

    l_mime_type := coalesce(p_mime_type,oos_util_web.get_mime_type(p_filename => p_filename));

    -- Set Header
    owa_util.mime_header(
      ccontent_type => l_mime_type,
      bclose_header => false );

    htp.p('Content-length: ' || dbms_lob.getlength(p_blob));

    htp.p(
      oos_util_string.sprintf(
        'Content-Disposition: %s; filename="%s"',
        p_content_disposition,
        p_filename));

    owa_util.http_header_close;

    -- download the BLOB
    wpg_docload.download_file(p_blob => l_blob);

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
   * @param p_clob
   */
  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
    p_clob in clob)
  as
    l_blob blob;
  begin

    l_blob := oos_util_lob.clob2blob(p_clob);

    download_file(
      p_filename => p_filename,
      p_mime_type => p_mime_type,
      p_content_disposition => p_content_disposition,
      p_blob => l_blob);
  end download_file;


  /**
   * TODO_Comments
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  -
   *
   * @author TODO
   * @created TODO
   * @param TODO
   * @return TODO
   */
  -- TODO mdsouza: is this a get?
  function parse_apex_url(
    p_url in varchar2,
    p_delimieter in varchar2 default ':'-- TODO mdsouza: check name that APEX uses
    )
    return rec_apex_url
  as
    l_return rec_apex_url;
    l_array apex_application_global.vc_arr2;
  begin

    l_array := apex_util.string_to_table(p_string => p_url, p_separator => p_delimieter);

    if l_array.count = 0 then
      null;
    else
      for i in 1..l_array.count loop
        if i = 1 then
          -- Page ID
          l_return.application_id := regexp_replace(l_array(i), '.*=');
        elsif i = 2 then
          l_return.page_id := l_array(i);
        elsif i = 3 then
          l_return.session_id := l_array(i);
        elsif i = 4 then
          l_return.request := l_array(i);
        elsif i = 5 then
          l_return.debug := l_array(i);
        elsif i = 6 then
          l_return.clear_cache := l_array(i);
        elsif i = 7 then
          l_return.items := l_array(i);
        elsif i = 8 then
          l_return.vals := l_array(i);
        elsif i = 9 then
          l_return.printer_friendly := l_array(i);
        elsif i = 10 then
          l_return.trace := l_array(i);
        end if;
      end loop;
    end if; -- l_array.count = 0

    return l_return;

  end parse_apex_url;



end oos_util_apex;
/
