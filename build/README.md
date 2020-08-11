# Building OOS Utils

*Note: This section is for developers working on and building OOS Utils.*
*Note: Please refer to the [`Development Guide`](../development-guide.md) for all PL/SQL development information.

OOS Utils install script is automatically generated. To generate the script run:

```bash
# This only needs to be done once
npm install

# Generates install and uninstall files
node app.js
```


## Files
| Filename | Description |
| ------------- | -------------|
| `app.js` | Main file to build the release. |
| `config.js` | Contains all the config options. Some are generated.|
| `fn.js` | Common functions used in `app.js` |
