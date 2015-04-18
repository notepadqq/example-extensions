var base = require('./base.js');

base.Nqq.commandLineArguments(function (retval, err) {
	console.log(retval);
});

base.Nqq.version(function (v) { 
	//console.log("Using Notepadqq version " + v);
	base.Nqq.print("Using Notepadqq version " + v);
});

base.Nqq.on("newWindow", function(window) {
	base.Nqq.print("New window created! (" + window.objectId() + ")");
	
	base.Nqq.print("Hello world");

	base.Nqq.testGetWindow(function (v) {
		console.log(v);
		console.log(v.objectId());
		base.Nqq.print("testGetWindow:", v.objectId());
	});
});