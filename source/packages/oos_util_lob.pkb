create or replace package body oos_util_lob
as

  -- ******** PUBLIC ********

  /**
   * Convers clob to blob
   *
   * Notes:
   *  -
   *
   * Related Tickets:
   *  - #12
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
    l_warning integer;
    l_lang_ctx integer := dbms_lob.default_lang_ctx;
  begin
    dbms_lob.createtemporary(l_blob, false, dbms_lob.session );
    dbms_lob.converttoblob(
      l_blob,
      p_clob,
      dbms_lob.lobmaxsize,
      l_dest_offset,
      l_src_offset,
      dbms_lob.default_csid,
      l_lang_ctx,
      l_warning);
    return l_blob;
  end clob2blob;

  /**
   * Converts blob to clob
   *
   * Notes:
   *  - Copied from http://stackoverflow.com/questions/12849025/convert-blob-to-clob
   *
   * Related Tickets:
   *  - #1
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
    l_dest_offsset integer := 1;
    l_src_offsset integer := 1;
    l_lang_context integer := dbms_lob.default_lang_ctx;
    l_warning integer;

  begin
    if p_blob is null then
      return null;
    end if;

    dbms_lob.createTemporary(
      lob_loc => l_clob,
      cache => false);

    dbms_lob.converttoclob(
      dest_lob => l_clob,
      src_blob => p_blob,
      amount => dbms_lob.lobmaxsize,
      dest_offset => l_dest_offsset,
      src_offset => l_src_offsset,
      blob_csid => dbms_lob.default_csid,
      lang_context => l_lang_context,
      warning => l_warning);

    return l_clob;
  end blob2clob;

end oos_util_lob;
/
