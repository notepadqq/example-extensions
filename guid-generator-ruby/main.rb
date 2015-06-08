require 'bundler/setup'
require 'notepadqq_api'
require 'securerandom'

$stdout.sync = true
$stderr.sync = true

# Initialize a new API instance
@api = NotepadqqApi.new

# Start the event loop
@api.run_event_loop do

  # Each time a new window gets opened, initialize it.
  @api.on_window_created do |window|
    # Add a menu item
    menu = window.addExtensionMenuItem(@api.extension_id, "Generate GUID")
    menu.on(:triggered) do
      window.currentEditor.setSelectionsText([SecureRandom.uuid])
    end
  end

end