require 'openssl'


# :nodoc: namespace
module Tem::Builders  

# Builder class and namespace for the cryptography builder.
class Crypto < Abi
  # Creates a builder targeting a module / class.
  #
  # The given parameter should be a class or module
  def self.define_crypto(class_or_module)  # :yields: crypto
    yield new(class_or_module)
  end
  
  # Defines the methods for handling an asymmetric (public/private) key.
  # 
  # ssl_class should be a class in OpenSSL::PKey. abi_type should be an ABI type
  # similar to those produced by packed_variable_length_numbers.
  #
  # The following methods are defined for a type named 'name':
  #   * read_private_name(array, offset) -> key
  #   * to_private_name(key) -> array
  #   * read_public_name(array, offset) -> key
  #   * to_public_name(key) -> array
  def asymmetric_key(name, ssl_class, privkey_abi_type, pubkey_abi_type,
                     hooks = {})
    object_wrapper "private_#{name}", ssl_class, [privkey_abi_type, nil],
                   { :read => hooks[:read_private], :to => hooks[:to_private] }
    object_wrapper "public_#{name}", ssl_class, [pubkey_abi_type, nil],
                   { :read => hooks[:read_public], :to => hooks[:to_public] }
  end
  
  # Defines the methods for a symmetric key.
  #
  # 
  def symmetric_key(name, cipher_class, key_abi_type, hooks = {})
    object_wrapper name, cipher_class, [key_abi_type, :key], hooks
  end
end  # class Crypto


# Implementation code for the Crypto methods.
module Crypto::Impl
  def self.key_from_array(array, offset, ssl_class, abi_type)
    key = ssl_class.new
    numbers = self.send :"read_#{abi_type}", array, offset
    numbers.each { |k, v| key.send :"#{k}=", v }
  end
  
  def self.key_to_array(key, abi_type)
    components = self.send :"#{abi_type}_components"
    numbers = Hash[*(components.map { |c| [c, key.send(c.to_sym) ]}.flatten)]
    self.send :"to_#{abi_type}", numbers
  end
end

end  # namespace Tem::Builders
