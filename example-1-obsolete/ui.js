// ui.js

/*
 * This example extension writes "Hello World" within the first opened tab.
 * In addition, it provides two menu options:
 *  - Big Text
 *  - Generate GUID
 */

//Importer.loadQtBinding("qt.core");
//Importer.loadQtBinding("qt.gui");

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

    var clipboard = QApplication.clipboard();
    var originalText = clipboard.text();
    clipboard->setText("funziona!");

    // Get the current editor in this window
    var editor = window.currentEditor();

    // Write to the editor
    editor.setValue("Hello World!");
    editor.markClean();

    // Add a new menu item
    var bigText = window.addExtensionMenuItem(extension.id(), "Big Text");
    bigText.triggered.connect(function(){
        editor.setZoomFactor(3);
    });

    // Add a new menu item
    var generateGUID = window.addExtensionMenuItem(extension.id(), "Generate GUID");
    generateGUID.triggered.connect(function(){
        editor.setSelectionsText([guid()]);
    });
}

// Connect the event "newWindow" to the function on_newWindow
nqq.newWindow.connect(on_newWindow);
