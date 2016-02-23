# OOS Utils Install Scripts

Both the install and uninstall scripts are stand alone scripts and do not reference any other files. You can copy them and use them outside of the project folder.

The install script acts both as a install and an upgrade script.

## Install/Upgrade

To install OOS Utils run the following in sql*plus:

```sql
@oos_util_install.sql
```

## Uninstall

To uninstall OOS Utils run the following in sql*plus:

```sql
@oos_util_uninstall.sql
```

## Objects

All oos_util objects are prefixed with `OOS_UTIL`.
