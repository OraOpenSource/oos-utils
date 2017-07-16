# Development Notes

## Where to Develop?

We will always create a new branch for each release. As such do not make pull requests to the master branch as that is the latest stable version of OOS Utils.

## `PLSQL_CCFLAGS`

Example script to test your code while developing:

`alter session set plsql_ccflags = 'UTL_FILE:TRUE';`

The following Conditional Compilation flags are used:

Flag Name | Type | Description
--- | --- | ---
`UTL_FILE` | `TRUE/FALSE` | If schema has access to `sys.utl_file` package
