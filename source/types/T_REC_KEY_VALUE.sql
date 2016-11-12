--------------------------------------------------------
--  DDL for Type T_REC_KEY_VALUE
--------------------------------------------------------

  CREATE OR REPLACE TYPE "T_REC_KEY_VALUE" 
AS
  OBJECT
  (
    KEY   VARCHAR2(4000),
    VALUE VARCHAR2(4000)
  );

/
