require './base'

Base.runEventLoop do
  nqq = Base.nqq
  
  puts nqq.version

  nqq.on(:newWindow) do |window|
    p window
    window.currentEditor.setValue("Ciao ;-)")
  end

end