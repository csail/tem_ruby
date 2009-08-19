# TEM life-cycle management using the APDU API. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2007 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Apdus


module Lifecycle
  def activate
    @transport.iso_apdu(:ins => 0x10)[:status] == 0x9000
  end
  def kill
    @transport.iso_apdu(:ins => 0x11)[:status] == 0x9000
  end
end

end  # namespace Tem::Apdus
