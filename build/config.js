// Storing config in a .js file to have ability to comment
var
  fs = require('fs'),
  path = require('path');

var
  objects = {}
  files = {
    install : '../install/oos_utils_install.sql',
    uninstall : '../install/oos_utils_uninstall.sql',
    createSynonyms : '../install/create_synonyms.sql',
    createGrants : '../install/grant_to_oos_utils.sql'
  },
  preInstall = {
    prereqs : '../source/scripts/prereqs.sql'
  },
  postInstall = {
    recompile : '../source/scripts/recompile.sql'
  }
;

// Tables
objects.tables = {};

objects.tables.oos_util_values = {
  src : '../source/tables/oos_util_values.sql',
  uninstall: 'drop table oos_util_values;'
};


// Data
objects.data = {};

objects.data.oos_util_values = {
  src : '../data/oos_util_values.sql'
};


// Packages
objects.packages = {
};

var packages = fs.readdirSync(path.resolve(__dirname,'../source/packages'));
for (var i = 0; i < packages.length; i++){
  var ext = path.extname(packages[i]);

  if (ext === '.pks'){
    var packageName = packages[i].slice(0, (-1 * ext.length));
    objects.packages[packageName] = {
      pks : '../source/packages/' + packageName + '.pks',
      pkb : '../source/packages/' + packageName + '.pkb'
    }
  }//if
}//packages


module.exports.objects = objects;
module.exports.files = files;
module.exports.preInstall = preInstall;
module.exports.postInstall = postInstall;
