require 'bundler/setup'
require 'notepadqq_api'
require 'securerandom'

$stdout.sync = true

# Initialize a new API instance
@notepadqqApi = NotepadqqApi.new

# Start the event loop
@notepadqqApi.runEventLoop do

  # Each time a new window gets opened, initialize it.
  @notepadqqApi.onWindowCreated do |window|
    # Add a menu item
    menu = window.addExtensionMenuItem(@notepadqqApi.extensionId, "Generate GUID")
    menu.on(:triggered) do
      window.currentEditor.setSelectionsText([SecureRandom.uuid])
    end
  end

end