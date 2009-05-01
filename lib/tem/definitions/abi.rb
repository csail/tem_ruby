module Tem::Abi
  Tem::Builders::Abi.define_abi self do |abi|
    abi.fixed_width_type :tem_byte, 1, :signed => true, :big_endian => true
    abi.fixed_width_type :tem_ubyte, 1, :signed => false, :big_endian => true
    abi.fixed_width_type :tem_short, 2, :signed => true, :big_endian => true
    abi.fixed_width_type :tem_ushort, 2, :signed => false, :big_endian => true    
    abi.fixed_width_type :tem_ps_addr, 20, :signed => false, :big_endian => true
    abi.fixed_width_type :tem_ps_value, 20, :signed => false,
                         :big_endian => true
  end

  # For convenience, include the Abi methods in Tem::Session's namespace.
  def self.included(klass)
    klass.extend Tem::Abi
  end
end  # module Tem::Abi
