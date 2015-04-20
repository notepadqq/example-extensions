require './base'

puts nqq.version

nqq.on(:newWindow) { |window|
  p window
  window.currentEditor.setValue("Ciao ;-)")
}

Base.runEventLoop