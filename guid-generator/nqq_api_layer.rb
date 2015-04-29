class MessageChannel
  require 'socket'
  require 'json'
  
  def initialize(socketPath)
    # Connect to Notepadqq socket
    @client = UNIXSocket.open(socketPath)
    
    @incomingBuffer = "" # Incomplete json messages (as strings)
    @parsedBuffer = [] # Unprocessed object messages
  end
  
  # Sends a JSON message to Notepadqq
  def sendMessage(msg)
    sendRawMessage(JSON.generate(msg))
  end
  
  # Read incoming messages
  def getMessages(block=true)
    
    begin
      if block and @incomingBuffer.empty? and @parsedBuffer.empty?
        read = @client.recv(1048576)
      else
        read = @client.recv_nonblock(1048576)
      end
    rescue
      read = ""
    end
    
    @incomingBuffer += read
    messages = @incomingBuffer.split("\n")
    
    if @incomingBuffer.end_with? "\n"
      # We only got complete messages: clear the buffer
      @incomingBuffer.clear
    else
      # We need to store the incomplete message in the buffer
      @incomingBuffer = messages.pop || ""
    end
    
    converted = []
    for i in 0...messages.length
      begin
        msg = JSON.parse(messages[i])
        converted.push(msg)
      rescue
        puts "Invalid message received."
      end
    end
    
    retval = @parsedBuffer + converted
    @parsedBuffer = []
    
    # Make sure that, when block=true, at least one message is received
    if block and retval.empty?
      retval += getMessages(true)
    end
    
    return retval
  end
  
  # Get the next message of type "result".
  # The other messages will still be returned by getMessages 
  def getNextResultMessage
    discarded = []
    
    while true do
      chunk = self.getMessages
      for i in 0...chunk.length
        if chunk[i].has_key?("result")
          discarded += chunk[0...i]
          discarded += chunk[i+1..-1]
          @parsedBuffer = discarded
          return chunk[i]
        end
      end
      
      discarded += chunk
    end
    
  end
  
  private
  
  # Sends a raw string message to Notepadqq
  def sendRawMessage(msg)
    @client.send(msg, 0)
  end
  
end

class MessageInterpreter
  
  def initialize(messageChannel)
    @messageChannel = messageChannel
    
    # Hash of event handlers, for example
    # {
    #   1: {
    #     "newWindow": [<callback1>, ..., <callbackn>]
    #   },
    #   ...
    # }
    # Where 1 is an objectId and "newWindow" is an event of that object
    @eventHandlers = {}
  end
  
  # Assign an event of a particular objectId to a callback
  def registerEventHandler(objectId, event, callback)
    event = event.to_sym
    
    @eventHandlers[objectId] ||= {}
    @eventHandlers[objectId][event] ||= []
    
    @eventHandlers[objectId][event].push(callback)
  end
  
  # Calls a method on the remote object objectId
  def invokeApi(objectId, method, args)
    message = {
      :objectId => objectId,
      :method => method,
      :args => args
    }
    
    @messageChannel.sendMessage(message)
    reply = @messageChannel.getNextResultMessage
    
    result = [reply["result"]]
    convertStubs!(result)
    result = result[0]
    
    # Fixme check for errors in reply["err"]
    
    return result
  end
  
  def processMessage(message)
    if message.has_key?("event")
      processEventMessage(message)
    elsif message.has_key?("result")
      # We shouldn't have received it here... ignore it
    end
  end
  
  private
  
  # Call the handlers connected to this event
  def processEventMessage(message)
    event = message["event"].to_sym
    objectId = message["objectId"]

    if @eventHandlers[objectId] and @eventHandlers[objectId][event]
      handlers = @eventHandlers[objectId][event]

      args = message["args"]
      convertStubs!(args)
      
      (handlers.length-1).downto(0).each { |i| 
        handlers[i].call(*args)
      }
    end
  end
  
  def convertStubs!(dataArray)
    # FIXME Use a stack
    
    dataArray.map! { |value|
      unless value.nil?
        if value.kind_of?(Array)
          convertStubs!(value)
          
        elsif value.kind_of?(Hash) and
              value["$__nqq__stub_type"].kind_of?(String) and
              value["id"].kind_of?(Fixnum)
          
          stubType = value["$__nqq__stub_type"]
          begin
            stub = Object::const_get(Stubs.name + "::" + stubType)
            stub.new(self, value["id"])
          rescue
            puts "Unknown stub: " + stubType
            value
          end
          
        elsif value.kind_of?(Hash)
          value.each do |key, data|
            tmpArray = [data]
            convertStubs!(tmpArray)
            value[key] = tmpArray[0]
          end
          
          value
          
        else
          value
        end
      end
    }
  end
  
end

module Stubs
  
  class Stub

    def initialize(messageInterpreter, id)
      @messageInterpreter = messageInterpreter
      @id = id
    end

    def on(event, &callback)
      @messageInterpreter.registerEventHandler(@id, event, callback)
    end

    def method_missing(method, *args, &block)  
      return @messageInterpreter.invokeApi(@id, method, args)
    end 
    
    def ==(other)
      other.class <= Stub && id == other.id
    end
    
    protected
    
    def id
      @id
    end

  end
  
  class Nqq < Stub; end
  class Editor < Stub; end
  class Window < Stub; end
  class MenuItem < Stub; end
  
end

class NqqApiLayer
  
  @@socketPath = ARGV[0]
  @@extensionId = ARGV[1]
  @@messageChannel = MessageChannel.new(@@socketPath)
  @@messageInterpreter = MessageInterpreter.new(@@messageChannel)
  
  # Start reading messages and calling event handlers
  def self.runEventLoop
    yield
    
    while true do
      messages = @@messageChannel.getMessages
      messages.each do |msg|
        @@messageInterpreter.processMessage(msg)
      end
    end
    
  end
  
  def self.extensionId
    return @@extensionId
  end
  
  # Returns an instance of Nqq
  def self.nqq
    @@nqq ||= Stubs::Nqq.new(@@messageInterpreter, 1);
    return @@nqq
  end
  
end