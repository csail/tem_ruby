# The transport module contains classes responsible for transferring low-level
# commands issed by the high-level TEM methods to actual TEMs, which can be
# connected to the system in various ways.  
module Tem::Transport

  # Shortcut for Tem::Transport::AutoConfigurator#auto_transport
  def self.auto_transport
    Tem::Transport::AutoConfigurator.auto_transport
  end
end
