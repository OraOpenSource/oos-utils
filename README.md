# OOS Utils

In most applications they're a common set of methods that developers consistently have to re-write. Things such as `is_number(p_string)`, `download_file(p_blob)`, etc. Not only does this add development time to projects, each iteration may have slight differences. The worst is that some of which even have bugs!

Enter OOS Utils. **OOS Utils provides a common set of PL/SQL utility methods that remove the need for the creation of common methods in each application**. Check out the docs below to see the complete list of methods OOS Utils provides. Never re-develop common methods again!

## Documentation

- [Read The Docs](http://oos-utils.readthedocs.org/en/latest/README/) which displays it in a nice, searchable format
- MD files in the [docs](/docs) folder

## Install

For quick install of the latest version of OOS Utils using [SQLcl](http://www.oracle.com/technetwork/developer-tools/sqlcl/downloads/index.html) run the following in SQLcl:

```sql
@https://observant-message.glitch.me/oos-utils/latest/oos_utils_install.sql
```

If you want to download a copy and install from a local file go to the [Install](/install) folder for instructions and installation file(s).

## Development

If you have a recommendations, please add your idea and/or snippet examples as an [issue](https://github.com/OraOpenSource/oos-utils/issues).

Starting with `1.1.0` all PRs should be the appropriate release branch rather than master.

### Build
If you are working on OOS Utils and want to test your build go to the [build](/build) folder for instructions.
