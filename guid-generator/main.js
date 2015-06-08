var NotepadqqApi = require("notepadqq-api")
var uuid = require('uuid');

var api = new NotepadqqApi.NotepadqqApi();

api.onWindowInitialization(function(window) {
	
	var menu = window.addExtensionMenuItem(api.extensionId, "Generate GUID")
	menu.on("triggered", function() {
		window.currentEditor().setSelectionsText([uuid.v4()]);
	});
	
});