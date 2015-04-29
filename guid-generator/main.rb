require 'bundler/setup'
require_relative 'base'
require 'securerandom'

Base.runEventLoop do
  nqq = Base.nqq
  
  initializedWindows = []

  nqq.on(:currentExtensionStarted) do
    nqq.windows.each do |window|
      unless initializedWindows.include? window
        initializedWindows.push window
        initWindow(window)
      end
    end
  end
  
  # Each time a new window gets opened, initialize it
  nqq.on(:newWindow) do |window|
    unless initializedWindows.include? window
      initializedWindows.push window
      initWindow(window)
    end
  end
  
  def initWindow(window)
    menu = window.addExtensionMenuItem(Base.extensionId, "Generate GUID")
    menu.on(:triggered) do
      window.currentEditor.setSelectionsText([SecureRandom.uuid])
    end
  end

end