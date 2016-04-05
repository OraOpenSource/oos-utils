var
  path = require('path'),
  fs = require('fs'),
  config = require('./config.js'),
  fn = require('./fn.js')
;

// Validations
fn.validatePackages(config.objects.packages);


// Generate Data
fn.generateDataOosUtilValues();


// Create Synonyms Script
fn.createSynonymScript(config);
fn.createGrantScript(config);



// Clear files
for (file in config.files){
  if (file !== 'createSynonyms' && file !== 'createGrants'){
    fn.writeFile(config.files[file], '');
  }
}


console.log('*** Generating Install File ***');

fn.appendFile(config.files.install,'-- DO NOT MODIFY THIS FILE. IT IS AUTO GENERATED\n');
fn.appendFile(config.files.install,'prompt *** OOS_UTILS ***\n\n');

fn.appendFile(config.files.install,'prompt *** Prereqs OOS_UTILS ***\n');
for (script in config.preInstall){
  fn.appendFile(files.install, fn.readFile(config.preInstall[script]));
}//config.objects.preInstall

fn.appendFile(config.files.install,'\n');
fn.appendFile(config.files.install,'prompt *** Installing OOS_UTILS ***\n\n\n');
fn.appendFile(config.files.install,'prompt *** TABLES ***\n');

for (table in config.objects.tables){
  fn.appendFile(files.install, 'prompt ' + table + '\n');
  fn.appendFile(files.install, fn.readFile(config.objects.tables[table].src));
}//tables

fn.appendFile(config.files.install,'prompt *** PACKAGES ***\n');
for (package in config.objects.packages){
  fn.appendFile(config.files.install,'prompt ' + package);
  fn.appendFile(files.install, fn.readFile(config.objects.packages[package].pks));
  fn.appendFile(files.install, fn.readFile(config.objects.packages[package].pkb));
}//packages


fn.appendFile(config.files.install,'\n\nprompt *** Post Install ***\n');
for (script in config.postInstall){
  fn.appendFile(files.install, fn.readFile(config.postInstall[script]));
}//config.objects.postInstall


fn.appendFile(config.files.install,'\n\nprompt *** Data ***\n');
for (myData in config.objects.data){
  fn.appendFile(config.files.install,'prompt ' + myData);
  fn.appendFile(files.install, fn.readFile(config.objects.data[myData].src));
}


console.log('*** Generating Uninstall File ***');
fn.appendFile(config.files.uninstall,'prompt *** Uninstalling OOS_UTILS ***\n\n\n');
fn.appendFile(config.files.uninstall,'prompt *** TABLES ***\n');
for (table in config.objects.tables){
  fn.appendFile(files.uninstall, 'prompt ' + table);
  fn.appendFile(files.uninstall, config.objects.tables[table].uninstall);
}//tables

fn.appendFile(config.files.uninstall,'\n\nprompt *** PACKAGES ***\n');
for (package in config.objects.packages){
  fn.appendFile(files.uninstall, 'prompt ' + package);
  fn.appendFile(files.uninstall, 'drop package ' + package + ';\n');
}//packages
