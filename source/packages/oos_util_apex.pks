create or replace package oos_util_apex
as
  -- CONSTANTS
  gc_content_disposition_inline constant varchar2(20) := 'inline';
  gc_content_disposition_attach constant varchar2(20) := 'attachment';

  type rec_apex_url is record(
    application_id apex_application_pages.application_id%type,
    page_id apex_application_pages.page_id%type,
    session_id apex_workspace_sessions.apex_session_id%type,
    request apex_workspace_activity_log.request_value%type,
    debug varchar2(4000),
    clear_cache varchar2(4000),
    items varchar2(4000),
    vals varchar2(4000),
    printer_friendly varchar2(4000),
    trace  varchar2(4000)
  );


  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
    p_blob in blob);

  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
    p_clob in clob);
end oos_util_apex;
/
