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
  
  # The TEM firmware version.
  #
  # Returns a hash with the keys +:major+ and +:minor+ whose values are version
  # numbers.
  def fw_version
    raw = @transport.iso_apdu :ins => 0x12
    return { :major => 0, :minor => 1 } if raw[:status] == 0x6D00
    if raw[:status] != 0x9000
      Smartcard::Iso::IsoCardMixin.raise_response_exception raw
    end
    
    { :major => read_tem_byte(raw[:data], 0),
      :minor => read_tem_byte(raw[:data], 1) }
  end
end

end  # namespace Tem::Apdus
