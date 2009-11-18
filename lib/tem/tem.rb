class Tem::Session
  include Tem::Abi
  include Tem::Apdus::Buffers
  include Tem::Apdus::Keys
  include Tem::Apdus::Lifecycle
  include Tem::Apdus::Tag
  
  include Tem::Admin::Emit
  include Tem::Admin::Migrate
  
  include Tem::CA
  include Tem::ECert
  include Tem::SeClosures
  include Tem::Toolkit
  
  CAPPLET_AID = [0x19, 0x83, 0x12, 0x29, 0x10, 0xBA, 0xBE]
  
  # The transport used for this TEM.
  attr_reader :transport
  
  # The TEM instance cache.
  #
  # This cache stores information about the TEM connected to this session. The
  # cache can be safely cleared without losing correctness.
  #
  # The cache should not be modified directly by client code.
  attr_reader :icache
  
  def initialize(transport)
    @transport = transport
    @transport.extend Smartcard::Gp::GpCardMixin
    @transport.select_application CAPPLET_AID
    
    @icache = {}
  end
    
  def disconnect
    return unless @transport
    @transport.disconnect
    @transport = nil
    clear_icache
  end
  
  # Clears the TEM instance cache.
  #
  # This should be called when connecting to a different TEM.
  def clear_icache
    @icache.clear
  end  
  
  def tem_secpack_error(response)
    raise "TEM refused the SECpack"
  end
end
