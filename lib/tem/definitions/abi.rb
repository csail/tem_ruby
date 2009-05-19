require 'openssl'


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
                            
    abi.packed_variable_length_numbers :tem_privrsa_numbers, :tem_ushort,
        [:p, :q, :dmp1, :dmq1, :iqmp], :signed => false, :big_endian => true
    abi.packed_variable_length_numbers :tem_pubrsa_numbers, :tem_ushort,
        [:e, :n], :signed => false, :big_endian => true
  end
  
  Tem::Builders::Crypto.define_crypto self do |crypto|
    crypto.asymmetric_key :tem_rsa, OpenSSL::PKey::RSA, :tem_privrsa_numbers,
        :tem_pubrsa_numbers, :read_private => lambda { |key|
      # a bit of math to rebuild the public key
      key.n = key.p * key.q
      p1, q1 = key.p - 1, key.q - 1          
      p1q1 = p1 * q1
      # HACK(costan): I haven't figured out how to restore d from dmp1 and
      # dmq1, so I'm betting on the fact that e must be a small prime.
      emp1 = key.dmp1.mod_inverse p1
      emq1 = key.dmq1.mod_inverse q1
      key.e = (emp1 < emq1) ? emp1 : emq1
      key.d = key.e.mod_inverse p1q1
      key
    }
  end

  # For convenience, include the Abi methods in Tem::Session's namespace.
  def self.included(klass)
    klass.extend Tem::Abi
  end
end  # module Tem::Abi
