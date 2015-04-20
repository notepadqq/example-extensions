require './base'

Base.runEventLoop do

  puts nqq.version

  nqq.on(:newWindow) { |window|
    p window
    window.currentEditor.setValue("Ciao ;-)")
  }

end