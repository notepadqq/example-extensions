import notepadqq_api
import uuid

# Initialize a new API instance
api = notepadqq_api.NotepadqqApi()

def on_started():

    # Each time a new window gets opened, initialize it.
    @api.for_each_window
    def init_window(window):
        
        # Add a menu item
        menu = window.addExtensionMenuItem(api.extension_id, "Generate GUID")
        
        @menu.on('triggered')
        def on_menu_triggered(checked):
            window.currentEditor().setSelectionsText([str(uuid.uuid4())])

    
# Start the event loop
api.run_event_loop(on_started)
