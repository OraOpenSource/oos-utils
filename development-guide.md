# Development Notes

## Where to Develop?

We will always create a new branch for each release. As such do not make pull requests to the master branch as that is the latest stable version of OOS Utils.

## Dev Standards

The following development standards are used for this project:

- Naming standards
  - parameters prefix `p_`
  - variables prefix: `l_`
  - constants prefix: `c_`
  - global constants prefix: `gc_`
- Tabs: space 2
- Everything in lowercase. I.e. no upper for keywords
- No unnecessary spacing/indentation of variables.
  - Write like you would in regular language.

## `PLSQL_CCFLAGS`

Example script to test your code while developing:

`alter session set plsql_ccflags = 'UTL_FILE:TRUE,APEX:TRUE';`

The following Conditional Compilation flags are used:

Flag Name | Type | Description
--- | --- | ---
`UTL_FILE` | `TRUE/FALSE` | If schema has access to `sys.utl_file` package

## Documentation

Don't modify the `docs` folder. The content is automatically generated from the JavaDoc documentation in the code.
