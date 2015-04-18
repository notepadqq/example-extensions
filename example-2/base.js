var net = require('net');

var socketPath = process.argv[2];
var extensionId = process.argv[3];

var server = net.Socket();
server.connect(socketPath);

function sendMessage(msg)
{
	server.write(msg + "\n");
}

var callbacks = [];
var eventHandlers = {};
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
	console.log(message);
	var dataObj = JSON.parse(message);
	
	if (dataObj["result"] !== undefined) {
		processResultMessage(dataObj);
	} else if (dataObj["event"] !== undefined) {
		processEventMessage(dataObj);
	}
}

function processResultMessage(message)
{
	var callback = callbacks.shift();
	
	if (callback !== undefined && callback !== null) {
		var err = message["err"];
	
		var result = [message["result"]];
		convertStubs(result, Stubs);
		result = result[0];
		
		callback(result, err);
	}
}

function processEventMessage(message)
{
	var event = message["event"];
	var objectId = message["objectId"];
	
	// See if there are handlers for this event
	if (eventHandlers[objectId] !== undefined && Array.isArray(eventHandlers[objectId][event])) {
		var handlers = eventHandlers[objectId][event];
		
		// Convert stubs
		var args = message["args"];
		convertStubs(args, Stubs);
		
		// Call handlers
		for (var i = handlers.length - 1; i >= 0; i--) {
			var fun = handlers[i];
			fun.apply(fun, args);
		}
	}
}
	
function convertStubs(dataArray, stubCollection)
{
	// FIXME Use a stack
	
	for (var i = 0; i < dataArray.length; i++) {
		if (dataArray[i] !== null && dataArray[i] !== undefined) {
			if (Array.isArray(dataArray[i])) {
				convertStubs(dataArray[i], stubCollection);
				
			} else if (typeof dataArray[i]["$__nqq__stub_type"] === 'string'
					   && typeof dataArray[i]["id"] === 'number') {
				
				var stubType = dataArray[i]["$__nqq__stub_type"];
					   
				if (typeof stubCollection[stubType] === 'function') {  
					var id = dataArray[i]["id"];
					dataArray[i] = new stubCollection[stubType](id);
				} else {
					console.error("Unknown stub: " + stubType);
				}
				
			} else if (typeof dataArray[i] === 'object') {
				for (var property in dataArray[i]) {
					if (dataArray[i].hasOwnProperty(property)) {
						var propValue = [dataArray[i][property]];
						convertStubs(propValue, Stubs);
						dataArray[i][property] = propValue[0];
					}
				}
			}
		}
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

function registerEventHandler(objectId, event, callback)
{
	if (eventHandlers[objectId] === undefined) {
		eventHandlers[objectId] = {};
	}
	
	if (eventHandlers[objectId][event] === undefined) {
		eventHandlers[objectId][event] = [];
	}
	
	eventHandlers[objectId][event].push(callback);
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
	
	object.on = function(event, callback) {
		registerEventHandler(objectId, event, callback);
	}
	
	object.objectId = function() { return objectId; }
	object.equals = function(other) { return typeof other.objectId === 'function' && this.objectId() === other.objectId(); }
}

var Stubs = {

	Editor: function (id)
	{
		initializeStub(this, id, ["setValue"]);
	},

	Nqq: function (id)
	{
		initializeStub(this, id, ["commandLineArguments", "version", "print"]);
	},

	Window: function (id)
	{
		initializeStub(this, id, ["addExtensionMenuItem", "currentEditor"]);
	},
	
	MenuItem: function (id)
	{
		initializeStub(this, id, []);
	},
	
}

module.exports.extensionId = extensionId;
module.exports.Nqq = new Stubs.Nqq(1);