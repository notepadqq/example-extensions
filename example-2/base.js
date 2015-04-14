var net = require('net');

var server = net.Socket();
server.connect('/tmp/srv');

function sendMessage(msg)
{
	server.write(msg + "\n");
}

var callbacks = [];
var bufferedData = "";

server.on('data', function (data) {
	var dataString = bufferedData + data.toString();
	var messages = data.toString().split("\n");
	
	// messages can be an array like the following ones:
	//     [msg1, msg2, ..., msgn, ""] => we received n complete messages.
	//     [msg1, msg2, ..., msgn] => we received n-1 complete messages, and an incomplete one.
	
	for (var i = 0; i < messages.length - 1; i++) {
		processMessage(messages[i]);
	}
	
	if (messages[messages.length - 1] === "") {
		// We only got complete messages: clear the buffer
		bufferedData = "";
	} else {
		// We need to store the incomplete message in the buffer
		bufferedData = messages[messages.length - 1];
	}
});

function processMessage(message)
{
	//console.log(message);
	var callback = callbacks.shift();
	
	// Convert data = ["type", id]
	var dataObj = JSON.parse(message);
	var retval = null;
	var err = dataObj["err"];
	
	/*if (dataObj[0] == 'Editor') {
		retval = new Editor(dataObj[1]);
	}*/
	retval = dataObj["return"];
	
	if (callback !== undefined && callback !== null) {
		callback(retval, err);
	}
}

function invokeApi (objectId, method, args, callback)
{
	callbacks.push(callback)
	
	var message = {
		objectId: objectId,
		method: method,
		args: args
	};
	
	sendMessage(JSON.stringify(message));
}

// Gets the implementation for a stub method with the specified name.
function getStubMethod(objectId, name)
{
	return function() {
		var callback = arguments[arguments.length - 1];
		var args = [];
		for (var i = 0; i < arguments.length; i++) {
			args.push(arguments[i]);
		}
		if (typeof(callback) === 'function') {
			args.pop();
		} else {
			callback = null;
		}
		
		return invokeApi(objectId, name, args, callback);
	}
}

// Initializes a stub with the provided methods.
function initializeStub(object, objectId, methods)
{
	for (var i = 0; i < methods.length; i++) {
		var name = methods[i];
		object[name] = getStubMethod(objectId, name);
	}
}

function Editor(id)
{
	initializeStub(this, id, []);
}

function Nqq(id)
{
	initializeStub(this, id, ["commandLineArguments", "version", "print"]);
}

//module.exports.invokeApi = invokeApi;
module.exports.Nqq = new Nqq(1);
//module.exports.sendMessage = sendMessage;
//module.exports.getEditorStub = getEditorStub;
