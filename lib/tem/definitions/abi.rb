# The TEM's ABI (Abstract Binary Interface) definition.
#
# This code is the official specification, because Victor likes executable
# specifications.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2007 Massachusetts Institute of Technology
# License:: MIT

require 'openssl'
require 'digest/sha1'


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
    abi.fixed_length_string :tem_3des_key_string, 16    
  end
  
  Tem::Builders::Crypto.define_crypto self do |crypto|
    crypto.crypto_hash :tem_hash, Digest::SHA1
    
    crypto.asymmetric_key :tem_rsa, OpenSSL::PKey::RSA, :tem_privrsa_numbers,
        :tem_pubrsa_numbers, 
        :read_private => lambda { |key|
      # The TEM uses the Chinese Remainder Theorem form of RSA keys, while
      # OpenSSL uses the straightforward form (n, e, d).

      # Rebuild the straightforward form from the CRT form.
      key.n = key.p * key.q
      p1, q1 = key.p - 1, key.q - 1          
      p1q1 = p1 * q1
      # HACK(costan): I haven't figured out how to restore d from dmp1 and
      # dmq1, so I'm betting on the fact that e must be a small prime.
      emp1 = key.dmp1.mod_inverse p1
      emq1 = key.dmq1.mod_inverse q1
      key.e = (emp1 < emq1) ? emp1 : emq1
      key.d = key.e.mod_inverse p1q1
      Tem::Keys::Asymmetric.new key
    }
    
    crypto.symmetric_key :tem_3des_key, OpenSSL::Cipher::DES, 'EDE-CBC',
                         :tem_3des_key_string
    
    crypto.conditional_wrapper :tem_key, 1,
        [{:tag => [0x99], :type => :tem_3des_key,
          :class => Tem::Keys::Symmetric },
         {:tag => [0xAA], :type => :public_tem_rsa,
          :class => Tem::Keys::Asymmetric,
          :predicate => lambda { |k| k.ssl_key.kind_of?(OpenSSL::PKey::RSA) &&
                                     k.is_public? } },
         {:tag => [0x55], :type => :private_tem_rsa,
          :class => Tem::Keys::Asymmetric,
          :predicate => lambda { |k| k.ssl_key.kind_of?(OpenSSL::PKey::RSA) } }]
  end
  
  # For convenience, include the Abi methods in Tem::Session's namespace.
  def self.included(klass)
    klass.extend Tem::Abi
  end
end  # module Tem::Abi
