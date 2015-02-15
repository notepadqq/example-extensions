// ui.js

/*
 * This example extension writes "Hello World" within the first opened tab.
 * In addition, it provides two menu options:
 *  - Big Text
 *  - Generate GUID
 */

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
}

function on_newWindow(window)
{
    print("new window created");
    
    var editor = window.currentEditor();
    editor.setValue("Hello World!");
    editor.markClean();
    
    var bigText = window.addExtensionMenuItem(extension.id(), "Big Text");
    bigText.triggered.connect(function(){
        editor.setZoomFactor(3);
    });
    
    var generateGUID = window.addExtensionMenuItem(extension.id(), "Generate GUID");
    generateGUID.triggered.connect(function(){
        editor.setSelectionsText([guid()]);
    });
}

nqq.newWindow.connect(on_newWindow);
