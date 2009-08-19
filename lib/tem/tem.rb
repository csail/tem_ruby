class Tem::Session
  include Tem::Abi
  include Tem::Apdus::Buffers
  include Tem::Apdus::Keys
  include Tem::Apdus::Lifecycle
  include Tem::Apdus::Tag
  
  include Tem::CA
  include Tem::ECert
  include Tem::SeClosures
  include Tem::Toolkit
  
  CAPPLET_AID = [0x19, 0x83, 0x12, 0x29, 0x10, 0xBA, 0xBE]
  
  attr_reader :transport
  
  def initialize(transport)
    @transport = transport
    @transport.extend Smartcard::Gp::GpCardMixin
    @transport.select_application CAPPLET_AID
  end
  
  def disconnect
    return unless @transport
    @transport.disconnect
    @transport = nil
  end
  
  def tem_secpack_error(response)
    raise "TEM refused the SECpack"
  end
end
