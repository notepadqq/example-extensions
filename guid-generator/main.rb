require 'bundler/setup'
require 'notepadqq_api'
require 'securerandom'

# Initialize a new API instance
@notepadqqApi = NotepadqqApi.new

# Start the event loop
@notepadqqApi.runEventLoop do
  
  # Get a reference to the main Notepadqq object
  @nqq = @notepadqqApi.notepadqq
  
  # Array of already initialized windows
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
    menu = window.addExtensionMenuItem(@notepadqqApi.extensionId, "Generate GUID")
    menu.on(:triggered) do
      window.currentEditor.setSelectionsText([SecureRandom.uuid])
    end
  end

end