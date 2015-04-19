require './base'

nqq = Stubs::Nqq.new(1);
puts nqq.version

nqq.on(:newWindow) { |window|
  p window
  window.currentEditor.setValue("Ciao ;-)")
}

Base.runEventLoop