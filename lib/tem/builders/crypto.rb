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
  # ssl_class should be a class in OpenSSL::PKey. privkey_abi_type and
  # pubkey_abi_type should be ABI types similar to those produced by
  # packed_variable_length_numbers.
  #
  # The following methods are defined for a type named 'name':
  #   * read_private_name(array, offset) -> key
  #   * to_private_name(key) -> array
  #   * private_name_class -> Class
  #   * read_public_name(array, offset) -> key
  #   * to_public_name(key) -> array
  #   * public_name_class -> Class
  def asymmetric_key(name, ssl_class, privkey_abi_type, pubkey_abi_type,
                     hooks = {})
    object_wrapper "private_#{name}", ssl_class, [privkey_abi_type, nil],
                   :read => hooks[:read_private] || hooks[:read],
                   :to => hooks[:to_private] || hooks[:to],
                   :new => hooks[:new_private] || hooks[:new] ||
                           lambda { |k| ssl_class.new }
    object_wrapper "public_#{name}", ssl_class, [pubkey_abi_type, nil],
                   :read => hooks[:read_public] || hooks[:read],
                   :to => hooks[:to_public] || hooks[:to],
                   :new => hooks[:new_private] || hooks[:new] ||
                           lambda { |k| ssl_class.new }
  end
  
  # Defines the methods for a symmetric key.
  #
  # cipher_class should be a class in OpenSSL::Cipher. key_abi_type should be
  # an ABI type similar to that produced by fixed_string.
  #
  # The following methods are defined for a type named 'name':
  #   * read_name(array, offset) -> object
  #   * to_name(object) -> array
  #   * name_class -> Class
  def symmetric_key(name, cipher_class, cipher_name, key_abi_type, hooks = {})
    object_wrapper name, cipher_class, [key_abi_type, :key],
        :new => lambda { |klass|
      k = klass.new cipher_name
      
      unless k.respond_to? :key
        # Some ciphers don't give back the key that they receive.
        # We need to synthesize that.
        class << k
          def key=(new_key)
            super
            @_key = new_key
          end
          def key
            @_key
          end
        end
      end
    }
  end
  
  # Defines the methods for a cryptographic hash function.
  #
  # digest_class should be an object similar to the classes in the Digest
  # name-space. Specifically, it should implement the digest method.
  #
  # The following methods are defined for a type named 'name':
  #   * name(array | String) -> array
  #   * name_length -> number
  #   * name_digest_class -> Class
  def crypto_hash(name, digest_class)
    digest_length = digest_class.digest('').length

    defines = Proc.new do 
      define_method :"#{name}" do |data|
        data = data.pack 'C*' unless data.kind_of? String
        digest_class.digest(data).unpack 'C*'
      end
      define_method(:"#{name}_digest_class") { digest_class }
      define_method(:"#{name}_length") { digest_length }
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines    
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
