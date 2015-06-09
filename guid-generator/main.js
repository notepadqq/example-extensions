var NotepadqqApi = require("notepadqq-api").NotepadqqApi
var uuid = require('uuid');

// Connect to notepadqq
NotepadqqApi.connect(function(api) {

    // We initialize each window here
    api.onWindowInitialization(function(window) {

        // Add a new menu item
        var menu = window.addExtensionMenuItem(api.extensionId, "Generate GUID")

        // Add an handler to the "triggered" event of the menu item
        menu.on("triggered", function() {
            window.currentEditor().setSelectionsText([uuid.v4()]);
        });

    });

});