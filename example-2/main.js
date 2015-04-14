var base = require('./base.js');

base.Nqq.commandLineArguments(function (retval, err) {
	console.log(retval);
});

base.Nqq.version(function (v) { 
	//console.log("Using Notepadqq version " + v);
	base.Nqq.print("Using Notepadqq version " + v);
})

base.Nqq.print("Hello world");

/*base.invokeApi(0, "hello", [], function (retval, err) {
	console.log("Hello called!");
});

base.invokeApi(1, "commandLineArguments", [], function (retval, err) {
	console.log(retval);
});*/

//base.sendMessage('weii');
//var editor = base.getEditorStub();
//editor.hello();