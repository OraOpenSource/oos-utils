# OOS Utils Install Scripts

Both the install and uninstall scripts are stand alone scripts and do not reference any other files. You can copy them and use them outside of the project folder.

The install script acts both as a install and an upgrade script.

## Install/Upgrade

For quick install of the latest version of OOS Utils using [SQLcl](http://www.oracle.com/technetwork/developer-tools/sqlcl/downloads/index.html) run the following in SQLcl:

```sql
@https://observant-message.glitch.me/oos-utils/latest/oos_utils_install.sql
```

If you want to download a copy and install from a local file:

[Download](https://observant-message.glitch.me/oos-utils/latest/oos-utils-latest.zip) the latest version of OOS Utils

To install OOS Utils run the following in sql*plus:

```sql
@install/oos_utils_install.sql
```

## Uninstall

To uninstall OOS Utils run the following in sql*plus:

```sql
@install/oos_utils_uninstall.sql
```

## Objects

All `oos_util` objects are prefixed with `OOS_UTIL`.
