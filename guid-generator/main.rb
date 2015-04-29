require 'bundler/setup'
require 'securerandom'
require_relative 'communication_interface'

CommunicationInterface.runEventLoop do
  
  @nqq = CommunicationInterface.nqq
  @initializedWindows = []

  # As soon as the extension is started, initialize
  # all the opened windows.
  @nqq.on(:currentExtensionStarted) do
    @nqq.windows.each do |window|
      initWindow(window)
    end
  end
  
  # Each time a new window gets opened, initialize it.
  # When Notepadqq is starting and initializing all the extensions,
  # we might not be fast enough to receive this event: this is why
  # we initialize windows on currentExtensionStarted too.
  @nqq.on(:newWindow) do |window|
    initWindow(window)
  end
  
  def initWindow(window)
    # It could happen that we try to initialize this window twice:
    # on @nqq.newWindow and on @nqq.currentExtensionStarted.
    # We avoid it by keeping track of which window we already initialized.
    return if @initializedWindows.include? window
    @initializedWindows.push window
    
    # Add a menu item
    menu = window.addExtensionMenuItem(CommunicationInterface.extensionId, "Generate GUID")
    menu.on(:triggered) do
      window.currentEditor.setSelectionsText([SecureRandom.uuid])
    end
  end

end