# :nodoc: namespace
module Tem::Apdus
  
module Lifecycle
  def activate
    @transport.applet_apdu(:ins => 0x10)[:status] == 0x9000
  end
  def kill
    @transport.applet_apdu(:ins => 0x11)[:status] == 0x9000
  end
end

end  # namespace Tem::Apdus
