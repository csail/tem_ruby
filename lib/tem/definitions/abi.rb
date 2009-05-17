module Tem::Abi
  Tem::Builders::Abi.define_abi self do |abi|
    abi.fixed_length_number :tem_byte, 1, :signed => true, :big_endian => true
    abi.fixed_length_number :tem_ubyte, 1, :signed => false, :big_endian => true
    abi.fixed_length_number :tem_short, 2, :signed => true, :big_endian => true
    abi.fixed_length_number :tem_ushort, 2, :signed => false,
                            :big_endian => true    
    abi.fixed_length_number :tem_ps_addr, 20, :signed => false,
                            :big_endian => true
    abi.fixed_length_number :tem_ps_value, 20, :signed => false,
                            :big_endian => true
                            
    abi.packed_variable_length_numbers :tem_privkey_numbers, :tem_ushort,
        [:p, :q, :dmp1, :dmq1, :iqmp], :signed => false, :big_endian => true
    abi.packed_variable_length_numbers :tem_pubkey_numbers, :tem_ushort,
        [:e, :n], :signed => false, :big_endian => true
  end

  # For convenience, include the Abi methods in Tem::Session's namespace.
  def self.included(klass)
    klass.extend Tem::Abi
  end
end  # module Tem::Abi
