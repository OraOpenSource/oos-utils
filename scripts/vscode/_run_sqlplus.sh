#!/bin/sh

# make sure script uses correct environment settings for sqlplus
# source ~/.profile

echo Parsing file: $2
# run sqlplus, execute the script, then get the error list and exit
# sqlcl $1 << EOF
sqlplus $1 << EOF
set define off
--
$2
--
show errors
-- @_show_errors.sql $3
exit;
EOF
