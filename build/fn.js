// Find index at end of param string (not at start)
String.prototype.indexOfEnd = function(string) {
  var io = this.indexOf(string);
  return io == -1 ? -1 : io + string.length;
}


var
  db = require('mime-db'),
  path = require('path'),
  fs = require('fs');


var functions = {
  generateDataOosUtilValues: function(){
    console.log('*** generateDataOosUtilValues ***');

    var
      sqlStmt = '',
      temp,
      extensions = {}
    ;

    var deleteElements = function(pSearch, pArray){
      //Make sure that at least one element exist for each ext
      for (var i = 0; i < pArray.length && pArray.length > 1; i++){
        // Remove application specific mime types
        if (pArray[i].indexOf(pSearch) >= 0){
          pArray.splice(i, 1);
          i += -1; //Since splice removes element from array need to adjust pointer
        }
      }
    }//deleteElements


    // db has the mime-type with an array of extensions
    // Reverse this to have extensions with array of mime-types
    console.log('Reversing mime-types and extensions');
    for (var key in db){
      if (db[key].extensions){
        var exts = db[key].extensions;
        for(var i = 0; i < exts.length; i++){
          //Check if it array already exists and if it's unique
          if(extensions[exts[i]] && extensions[exts[i]].indexOf(key) < 0){
            extensions[exts[i]].push(key);
          }
          else{
            extensions[exts[i]] = [key];
          }
        }//for i
      }
    }//for key


    // Some extensions will have multiple mime-types.
    // Adjust down to one per extension
    console.log('Reducing to one mime-type per extension');
    for (var ext in extensions){

      //Take several passes to get down to one mime-type per extension
      var j = 0;
      while (extensions[ext].length > 1){
        switch(j){
          case 0:
            //First pass, remove non-standard mime types
            deleteElements('/x-', extensions[ext]);
            break;
          case 1:
            deleteElements('application/', extensions[ext]);
          case 2:
            deleteElements('audio/wave', extensions[ext]);
          case 3:
            deleteElements('image/', extensions[ext]);
        }//switch

        j++;

        // Error out if we can't filter down
        if (j > 10){
          console.log('Can\'t filter down mime-type');
          console.log(ext, ':', extensions[ext]);
          process.exit(1);
        }
      }//while

    }//for duplicates

    console.log('Creating insert statement');
    //Create insert statement
    sqlStmt  = '-- This file is generated, do not modify.\n\n';
    sqlStmt += 'begin\n  delete oos_util_values;\n';
    sqlStmt += '  insert all\n';
    for(var ext in extensions){
      temp = "    into oos_util_values(cat, name, value) values('mime-type', '%name%','%value%')\n";
      temp = temp.replace(/\%name\%/g, ext);
      temp = temp.replace(/\%value\%/g, extensions[ext][0]);
      sqlStmt += temp;
    }
    sqlStmt += '  select 1 from dual;\n';
    sqlStmt += 'end;\n'
    sqlStmt += '/\n';
    sqlStmt += 'commit;\n';

    fs.writeFileSync(path.resolve(__dirname,'../data/oos_util_values.sql'), sqlStmt);

  },//generateDataOosUtilValues

  appendFile : function (pFile, pContent){
    fs.appendFileSync(path.resolve(__dirname,pFile), pContent + '\n');
  },// appendFile

  readFile : function (pFile){
    return fs.readFileSync(path.resolve(__dirname,pFile),'utf8');
  },// readFile

  writeFile : function (pFile, pContent){
    fs.writeFileSync(path.resolve(__dirname,pFile), pContent);
  },// writeFile

  /**
   * Checks that package files all contain a "/" at EOF so it will compile properly in SQL*Plus
   *
   *
   * Related Tickets:
   *  - #37
   *
   * @param pPackages JSON object of packages (use config.objects.packages)
   */
  validatePackages : function(pPackages){
    var
      contents,
      error = false;

    for (var packageName in pPackages){
      for (var fileExt in pPackages[packageName]){
        contents = this.readFile(pPackages[packageName][fileExt]);

        // #37
        if (contents.search(/\/\n*$/) === -1){
          console.log('File missing "/" at end: ' + pPackages[packageName][fileExt]);
          error = true;
        }
      }// fileExt
    }//packageName

    if (error){
      process.exit(1);
    }

  },//validatePackages

  /**
   * Creates Synonym script
   *
   */
  createSynonymScript : function (pConfig){
    var template = 'create or replace synonym %OBJECT% for &from_user..%OBJECT%;\n';

    var temp = this.readFile(pConfig.files.createSynonyms);

    temp = temp.slice(0,temp.indexOfEnd('-- AUTOREPLACE_START'));
    temp += '\n\n';

    // Don't do tables since tables aren't officially supported or necessary yet
    for (var package in pConfig.objects.packages){
      temp += template.replace(/%OBJECT%/g, package);
    }//package

    this.writeFile(pConfig.files.createSynonyms, temp);

  },//createSynonymScript

  /**
   * Creates Grant script
   *
   */
  createGrantScript : function (pConfig){
    var template = {
      execute : 'grant execute on %OBJECT% to &to_user;\n'
    };

    var temp = this.readFile(pConfig.files.createGrants);

    temp = temp.slice(0,temp.indexOfEnd('-- AUTOREPLACE_START'));
    temp += '\n\n';

    // Don't do tables since tables aren't officially supported or necessary yet
    for (var package in pConfig.objects.packages){
      temp += template.execute.replace(/%OBJECT%/g, package);
    }//package

    this.writeFile(pConfig.files.createGrants, temp);

  }//createGrantScript
};// functions


module.exports = functions;
