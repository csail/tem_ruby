# Ruby implementation of the TEM's symmetric key operations.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Keys


# Wraps a TEM symmetric key, e.g. an AES key.
class Symmetric < Tem::Key
  @@cipher_mode = 'EDE-CBC'
  @@signature_mode = 'CBC'
  
  # Generates a new symmetric key.
  def self.generate
    cipher = OpenSSL::Cipher::DES.new @@cipher_mode
    key = cipher.random_key
    self.new key
  end
  
  # Creates a new symmetric key based on an OpenSSL Cipher instance, augmented
  # with a key accessor.
  #
  # Args:
  #   ssl_key:: the OpenSSL key, or a string containing the raw key
  #   raw_key:: if the OpenSSL key does not support calls to +key+, the raw key
  def initialize(ssl_key, raw_key = nil)
    if ssl_key.kind_of? OpenSSL::Cipher
      @key = raw_key || ssl_key.key
      @cipher_class = ssl_key.class
    else
      @key = ssl_key
      @cipher_class = OpenSSL::Cipher::DES
    end
    
    # Create an OpenSSL wrapper for the key we received.
    cipher = @cipher_class.new @@cipher_mode
    class <<cipher
      def key=(new_key)
        super
        @_key = new_key
      end
      def key
        @_key
      end
    end
    cipher.key = @key
    cipher.iv = "\0" * 16

    super cipher
  end
  public_class_method :new

  def encrypt_or_decrypt(data, do_encrypt)
    cipher = @cipher_class.new @@cipher_mode
    do_encrypt ? cipher.encrypt : cipher.decrypt
    cipher.key = @key
    cipher.iv = "\0" * 16
    cipher.padding = 0

    pdata = data.respond_to?(:pack) ? data.pack('C*') : data
    if do_encrypt
      pdata << "\x80"
      if pdata.length % cipher.block_size != 0
        pdata << "\0" * (cipher.block_size - pdata.length % cipher.block_size)
      end
    end
    
    result = cipher.update pdata
    result += cipher.final
    
    unless do_encrypt
      result_length = result.length
      loop do
        result_length -= 1
        next if result[result_length].ord == 0
        raise "Invalid padding" unless result[result_length].ord == 0x80
        break
      end
      result = result[0, result_length]
    end        
    data.respond_to?(:pack) ? result.unpack('C*') : result
  end
  
  def encrypt(data)
    encrypt_or_decrypt data, true
  end

  def decrypt(data)
    encrypt_or_decrypt data, false
  end

  def sign(data)    
    cipher = @cipher_class.new @@cipher_mode
    cipher.encrypt
    cipher.key = @key
    cipher.iv = "\0" * 16
    cipher.padding = 0
    
    pdata = data.respond_to?(:pack) ? data.pack('C*') : data
    pdata << "\x80"
    if pdata.length % cipher.block_size != 0
      pdata << "\0" * (cipher.block_size - pdata.length % cipher.block_size)
    end
    
    result = cipher.update pdata
    result += cipher.final
    result = result[-cipher.block_size, cipher.block_size]
    data.respond_to?(:pack) ? result.unpack('C*') : result
  end

  def verify(data, signature)
    hmac = sign(data)
    hmac = hmac.pack('C*') if hmac.respond_to?(:pack)
    signature = signature.pack('C*') if signature.respond_to?(:pack)
    hmac == signature
  end

  def self.new_from_array(array)    
    cipher_class = array[0].split('::').inject(Kernel) do |scope, name|
      scope.const_get name
    end
    
    # Cipher instance used solely to point to the right class.
    cipher = cipher_class.new @@cipher_mode
    self.new cipher, array[1]      
  end
  
  def self.new_from_yaml_str(yaml_str)
    array = YAML.load yaml_str
    new_from_array array
  end

  def to_array
    [@cipher_class.name, @key]
  end
  
  def to_yaml_str
    self.to_array.to_yaml.to_s
  end
end  # class Tem::Keys::Symmetric

end  # namespace Tem::Keys
