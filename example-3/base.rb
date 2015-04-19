class Base
  require 'socket'
  require 'json'
  
  @@socketPath = ARGV[0]
  @@extensionId = ARGV[1]

  @@client = UNIXSocket.open(@@socketPath)
  
  @@incomingBuffer = "" # Partial string messages
  @@parsedBuffer = [] # Unprocessed object messages
  
  @@eventHandlers = {}
  
  def self.registerEventHandler(objectId, event, callback)
    @@eventHandlers[objectId] ||= {}
    @@eventHandlers[objectId][event] ||= []
    
    @@eventHandlers[objectId][event].push(callback)
  end
  
  def self.invokeApi(objectId, method, args)
    message = {
      :objectId => objectId,
      :method => method,
      :args => args
    }
    
    self.sendRawMessage(JSON.generate(message))
    reply = self.getNextResultMessage
    
    result = [reply["result"]]
    convertStubs!(result)
    result = result[0]
    
    # Fixme check for errors in reply["err"]
    
    return result
  end

  def self.runEventLoop
    
    while true do
      messages = self.getMessages
      messages.each do |msg|
        if msg.has_key?("event")
          self.processEventMessage(msg)
        elsif msg.has_key?("result")
          # We shouldn't have received it here... ignore it
        end
      end
    end
    
  end
  
private
  
  def self.sendRawMessage(msg)
    @@client.send(msg, 0)
  end
  
  # Read incoming messages
  def self.getMessages(block=true)
    
    begin
      if block
        read = @@client.recv(1048576)
      else
        read = @@client.recv_nonblock(1048576)
      end
    rescue
      return []
    end
    
    @@incomingBuffer += read
    messages = @@incomingBuffer.split("\n")
    
    if @@incomingBuffer.end_with? "\n"
      # We only got complete messages: clear the buffer
      @@incomingBuffer.clear
    else
      # We need to store the incomplete message in the buffer
      @@incomingBuffer = messages.pop
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
    
    retval = @@parsedBuffer + converted
    @@parsedBuffer = []
    return retval
  end
  
  # Get the next message of type "result".
  # The other messages will still be returned by self.getMessages 
  def self.getNextResultMessage
    discarded = []
    
    while true do
      chunk = self.getMessages
      for i in 0...chunk.length
        if chunk[i].has_key?("result")
          discarded += chunk[0...i]
          discarded += chunk[i+1..-1]
          @@parsedBuffer = discarded
          return chunk[i]
        end
      end
      
      discarded += chunk
    end
    
  end
  
  def self.convertStubs!(dataArray)
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
            stub.new(value["id"])
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
  
  def self.processEventMessage(message)
    event = message["event"]
    objectId = message["objectId"]
    
    if @@eventHandlers[objectId] and @@eventHandlers[objectId][event]
      handlers = @@eventHandlers[objectId][event]
      
      args = message["args"]
      convertStubs!(args)
      
      (args.length-1).downto(0).each { |i| 
        handlers[i].call(*args)
      }
    end
  end

end

module Stubs
  
  class Stub

    def initialize(id)
      @id = id
    end

    def on(event, &callback)
      Base.registerEventHandler(@id, event, callback)
    end

    def method_missing(method, *args, &block)  
      return Base.invokeApi(@id, method, args)
    end 

  end
  
  class Nqq < Stub; end
  class Editor < Stub; end
  class Window < Stub; end
  class MenuItem < Stub; end
  
end