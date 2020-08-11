create or replace package body oos_util_transform as

  /**
   * converts a ref cursor to a canonical oracle xml
   * Notes:
   *  - This is just a wrapper for dbms_xmlgen so refer to the [Oracle documentation](http://docs.oracle.com/cd/E11882_01/appdev.112/e40758/d_xmlgen.htm)
   *
   *
   * @example
   * declare
   *   v_rc sys_refcursor;
   *   v_xml1 xmltype;
   * begin
   *   open v_rc for select dummy from dual;
   *   v_xml1 := oos_util_transform.refcur2xml(v_rc);
   * end;
   *
   * @issue #54
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-May-2016
   * @param p_rc Refcursor
   * @param p_null_handling Null conversion configuration
   * @return xmltype
   */
  function refcur2xml(
    p_rc in sys_refcursor,
    p_null_handling in number default dbms_xmlgen.null_attr)
    return xmltype
  as
    l_context dbms_xmlgen.ctxhandle;
    l_xml xmltype;
  begin
    l_context := dbms_xmlgen.newcontext(p_rc);

    dbms_xmlgen.setnullhandling(l_context, p_null_handling);

    l_xml := dbms_xmlgen.getxmltype(l_context, dbms_xmlgen.none);

    dbms_xmlgen.closecontext(l_context);

    return l_xml;
  end;

  /**
   * Checks if xmltype has rows
   *
   * @issue #15
   *
   * @example
   * declare
   *   v_rc sys_refcursor;
   *   v_xml1 xmltype;
   *   v_bool boolean;
   * begin
   *   open v_rc for select dummy from dual;
   *   v_xml1 := oos_util_transform.refcur2xml(v_rc);
   *   v_bool := oos_util_transform.xml_has_rows(v_xml1);
   * end;
   * /
   *
   * TRUE
   * FALSE
   *
   * @author Zach Hudock
   * @created 27-JUN-2016
   * @param p_xml XML to validate
   * @return True or false
   */
  function xml_has_rows(p_xml in xmltype)
    return boolean
  as
    l_num number;
  begin
    select count(1) into l_num from dual where existsnode(p_xml, '/ROWSET/ROW') = 1;
    return (l_num > 0);
  end xml_has_rows;

   /**
   * transforms a canonical oracle xml with user provided xslt
   *
   * see refcur2json for an example
   *
   * @issue #54
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-May-2016
   * @param p_in xmltype input to be transformed
   * @param p_trans xmltype XSLT translation string
   * @return xmltype
   */
  function xslt(
    p_in in xmltype,
    p_trans in xmltype)
    return xmltype
  as
  begin
    return p_in.transform(p_trans);
  end;

  /**
   * transforms a canonical oracle xml with user provided xquery
   *
   * see refcur2html for an example
   *
   * @issue #54
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-May-2016
   * @param p_in xmltype input to be transformed
   * @param p_trans varchar2 xquery string
   * @return xmltype
   */
  function xquery(
    p_in in xmltype,
    p_trans in varchar2)
    return xmltype
  as
    l_out xmltype;
  begin
    select xmlquery(p_trans passing p_in returning content) into l_out from dual;
    return l_out;
  end;

  /**
   * transforms a ref cursor to csv using xquery
   *
   * @issue #54
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-May-2016
   * @param p_rc refcursor to transform
   * @param p_column_names boolean to include column names or not, default false
   * @return clob
   */
  function refcur2csv(
    p_rc in sys_refcursor,
    p_column_names in boolean default false,
    p_return_empty in boolean default false)
    return clob
  as
    v_xml1 xmltype;
    v_xml2 xmltype;
    -- see: http://stackoverflow.com/questions/14088881/xml-to-csv-conversion-using-xquery
    c_xquery constant varchar2(32767) := q'[
    let $nl := codepoints-to-string(10),
        $q := codepoints-to-string(34),
        $nodes := /ROWSET/ROW
    for $i in $nodes
       return concat(string-join($i/*/concat($q, normalize-space(replace(data(.), $q, concat($q,$q))), $q), ','),$nl)
    ]';
    c_xquery_names constant varchar2(32767) := q'[
    let $nl := codepoints-to-string(10),
        $q := codepoints-to-string(34),
        $nodes := /ROWSET/ROW
        return concat(
            string-join(distinct-values($nodes/*/concat($q, name(.), $q)), ','),
            $nl,
            string-join(
                for $i in $nodes
                    return string-join($i/*/concat($q, normalize-space(replace(data(.), $q, concat($q,$q))), $q),','),$nl),
            $nl
        )
    ]';
  begin
    v_xml1 := refcur2xml(p_rc);

    if not xml_has_rows(v_xml1) and p_return_empty THEN
      return null;
    end if;

    if p_column_names
    then
      v_xml2 := xquery(v_xml1, c_xquery_names);
    else
      v_xml2 := xquery(v_xml1, c_xquery);
    end if;
    return entity_decode(v_xml2.getclobval());
  end;

  /**
   * transforms a ref cursor to csv using dbms_sql
   *
   * @issue #54
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-May-2016
   * @param p_rc refcursor to transform
   * @param p_column_names boolean to include column names or not, default false
   * @param p_separator column separator, default to comma
   * @param p_endline line endings to print in CSV, default to CRLF
   * @param p_date_fmt format to display date columns
   * @return clob
   */
  function refcur2csv2(
    p_rc           in out sys_refcursor,
    p_column_names in boolean default false ,
    p_separator    in varchar2 default ',',
    p_endline      in varchar2 default chr(13)||chr(10),
    p_date_fmt     in varchar2 default 'YYYY-MM-DD HH24:MI:SS')
    return clob
  as
    v_lob clob;
    v_cur_id pls_integer;
    v_col_count pls_integer;
    v_col_desc dbms_sql.desc_tab3;

    v_var_varchar2 varchar2(32767);
    v_var_number number;
    v_var_date date;

    v_buf varchar2(32767);
  begin
    dbms_lob.createtemporary(lob_loc => v_lob,
                             cache   => false,
                             dur     => dbms_lob.call);

    v_cur_id := dbms_sql.to_cursor_number(p_rc);

    dbms_sql.describe_columns3(v_cur_id, v_col_count, v_col_desc);

    if p_column_names
    then
      for i in 1 .. v_col_count
      loop
        v_buf := '"' || v_col_desc(i).col_name || '"';
        if i < v_col_count
        then
          v_buf := v_buf || p_separator;
        end if;
        dbms_lob.writeappend(v_lob, length(v_buf), v_buf);
      end loop;
      dbms_lob.writeappend(v_lob, length(p_endline), p_endline);
    end if;

    for i in 1 .. v_col_count
    loop
      case v_col_desc(i).col_type
        -- Numeric codes for Oracle built-in data types
        -- See https://docs.oracle.com/cd/B10501_01/server.920/a96540/sql_elements2a.htm#45504
        when  1 then dbms_sql.define_column(v_cur_id, i, v_var_varchar2, 32767);
        when  2 then dbms_sql.define_column(v_cur_id, i, v_var_number);
        when 12 then dbms_sql.define_column(v_cur_id, i, v_var_date);
        when 96 then dbms_sql.define_column(v_cur_id, i, v_var_varchar2, 32767);
        else         dbms_sql.define_column(v_cur_id, i, v_var_varchar2, 32767);
      end case;
    end loop;

    -- A (double) quote character in a field must be represented by two
    -- (double) quote characters.
    while dbms_sql.fetch_rows(v_cur_id) > 0
    loop
      for i in 1 .. v_col_count
      loop
        case v_col_desc(i).col_type
          when  2 then
            dbms_sql.column_value(v_cur_id, i, v_var_number);
            v_buf := to_char(v_var_number); -- TODO format model
          when 12 then
            dbms_sql.column_value(v_cur_id, i, v_var_date);
            v_buf := '"' || to_char(v_var_date, p_date_fmt) || '"';
          when 96 then
            dbms_sql.column_value(v_cur_id, i, v_var_varchar2);
            v_buf := '"' || regexp_replace(v_var_varchar2, '(' || chr(34) || ')', '\1' || '\1') || '"';
          else
            dbms_sql.column_value(v_cur_id, i, v_var_varchar2);
            v_buf := '"' || regexp_replace(v_var_varchar2, '(' || chr(34) || ')', '\1' || '\1') || '"';
        end case;
        if i < v_col_count
        then
          v_buf := v_buf || p_separator;
        end if;
        dbms_lob.writeappend(v_lob, length(v_buf), v_buf);
      end loop;
      dbms_lob.writeappend(v_lob, length(p_endline), p_endline);
    end loop;

    return v_lob;
  end;

  /**
   * transforms a ref cursor to html table using xquery
   *
   * notes:
   *  - inspired by Tom Kyte blog post http://tkyte.blogspot.com/2006/01/i-like-online-communities.html
   *
   * @issue #54
   *
   * @author Zach Hudock
   * @created 7-June-2016
   * @param p_rc refcursor to transform
   * @return clob
   */
  function refcur2html(
    p_rc in sys_refcursor,
    p_return_empty in boolean default false)
    return clob
  as
    v_xml1 xmltype;
    v_xml2 xmltype;
    c_xquery constant varchar2(32767) := q'[<table>
  <thead>
    <tr>{ for $i in /ROWSET/ROW[1]/* return <th>{name($i)}</th> }</tr>
  </thead>
  <tbody>
  {
    for $i in /ROWSET/* return <tr>{ for $j in $i/* return <td>{data($j)}</td> }</tr>
  }
  </tbody>
</table>]';
  begin
    v_xml1 := refcur2xml(p_rc);
    if not xml_has_rows(v_xml1) and p_return_empty THEN
      return null;
    end if;
    v_xml2 := xquery(v_xml1, c_xquery);
    return entity_decode(v_xml2.getclobval());
  end;

  /**
   * transforms a ref cursor to json using xslt
   *
   * notes:
   *  - XSLT document from https://github.com/doekman/xml2json-xslt
   *
   * @issue #54
   *
   * @author Zach Hudock
   * @created 7-June-2016
   * @param p_rc refcursor to transform
   * @return clob
   */
  function refcur2json(
    p_rc in sys_refcursor,
    p_return_empty in boolean default false)
    return clob
  as
    v_xml1 xmltype;
    v_xml2 xmltype;
    c_json_xslt constant xmltype := xmltype('<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
  Copyright (c) 2006, Doeke Zanstra
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer. Redistributions in binary
  form must reproduce the above copyright notice, this list of conditions and the
  following disclaimer in the documentation and/or other materials provided with
  the distribution.

  Neither the name of the dzLib nor the names of its contributors may be used to
  endorse or promote products derived from this software without specific prior
  written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
  THE POSSIBILITY OF SUCH DAMAGE.
-->

  <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="text/x-json"/>
  <xsl:strip-space elements="*"/>
  <!--contant-->
  <xsl:variable name="d">0123456789</xsl:variable>

  <!-- ignore document text -->
  <xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]"/>

  <!-- string -->
  <xsl:template match="text()">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="."/>
    </xsl:call-template>
  </xsl:template>

  <!-- Main template for escaping strings; used by above template and for object-properties
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <xsl:template name="escape-string">
    <xsl:param name="s"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''\'')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''\''),''\\'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,''\'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''&quot;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&quot;''),''\&quot;'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,''&quot;'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can''t escape backslash
       or double quote here, because they don''t replace characters (&#x0; becomes \t), but they prefix
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be
       processed first. This function can''t do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <!-- tab -->
      <xsl:when test="contains($s,''&#x9;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#x9;''),''\t'',substring-after($s,''&#x9;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- line feed -->
      <xsl:when test="contains($s,''&#xA;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xA;''),''\n'',substring-after($s,''&#xA;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- carriage return -->
      <xsl:when test="contains($s,''&#xD;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xD;''),''\r'',substring-after($s,''&#xD;''))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- number (no support for javascript mantise) -->
  <xsl:template match="text()[not(string(number())=''NaN'')]">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- boolean, case-insensitive -->
  <xsl:template match="text()[translate(.,''TRUE'',''true'')=''true'']">true</xsl:template>
  <xsl:template match="text()[translate(.,''FALSE'',''false'')=''false'']">false</xsl:template>

  <!-- item:null -->
  <xsl:template match="*[count(child::node())=0]">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="local-name()"/>
    </xsl:call-template>
    <xsl:text>:null</xsl:text>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if> <!-- MBR 30.01.2010: added this line as it appeared to be missing from stylesheet -->
  </xsl:template>

  <!-- object -->
  <xsl:template match="*" name="base">
    <xsl:if test="not(preceding-sibling::*)">{</xsl:if>
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="name()"/>
    </xsl:call-template>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates select="child::node()"/>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if>
  </xsl:template>

  <!-- array -->
  <xsl:template match="*[count(../*[name(../*)=name(.)])=count(../*) and count(../*)&gt;1]">
    <xsl:if test="not(preceding-sibling::*)">[</xsl:if>
    <xsl:choose>
      <xsl:when test="not(child::node())">
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="child::node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">]</xsl:if>
  </xsl:template>

  <!-- convert root element to an anonymous container -->
  <xsl:template match="/">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

</xsl:stylesheet>');
  begin
    v_xml1 := refcur2xml(p_rc);
    if not xml_has_rows(v_xml1) and p_return_empty THEN
      return null;
    end if;
    v_xml2 := xslt(v_xml1, c_json_xslt);
    return entity_decode(v_xml2.getclobval());
  end;

  /**
   * convert encoded XML entities to decoded characters (e.g. &quot; -> ")
   *
   * @issue #54
   *
   * @author Zach Hudock
   * @created 07-June-2016
   * @param p_in clob
   * @return clob
   */
  function entity_decode(
    p_in clob)
    return clob
  as
  begin
    return dbms_xmlgen.convert(p_in, dbms_xmlgen.entity_decode);
  end;
end oos_util_transform;
/
