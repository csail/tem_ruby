require 'openssl'
require 'digest'
require 'yaml'

module Tem::CryptoAbi
  include Tem::Abi
  
  # The methods that will be mixed into the TEM module
  module MixedMethods    
    # The length of a TEM symmetric key.
    def tem_symmetric_key_length
      16 # 128 bits
    end
            
    def read_tem_key(buffer, offset)
      key_type = read_tem_ubyte buffer, offset
      case key_type
      when 0x99
        key = buffer[offset + 1, tem_symmetric_key_length]                
      when 0xAA
        key = read_public_tem_rsa buffer, offset + 1
      when 0x55
        key = read_private_tem_rsa buffer, offset + 1
      else
        raise "Invalid key type #{'%02x' % key_type}"
      end
      return new_key_from_ssl(key, (key_type == 0xAA)) 
    end
    
    def to_tem_key(ssl_key, type)
      case type
      when :public
        to_public_tem_rsa(ssl_key).unshift 0xAA
      when :private
        to_private_tem_rsa(ssl_key).unshift 0x55
      else
        # symmetric key
      end
    end
    
    # Creates a new TEM key wrapper from a SSL key
    def new_key_from_ssl(ssl_key, is_public)
      if ssl_key.kind_of? OpenSSL::PKey::RSA
        AsymmetricKey.new ssl_key, is_public, :pkcs1
      else
        SymmetricKey.new ssl_key
      end
    end
    
    # Compute a cryptographic hash in the same way that the TEM does.
    def hash_for_tem(data)
      data = data.pack 'C*' unless data.kind_of? String
      Digest::SHA1.digest(data).unpack 'C*'
    end
  end
  
  self.extend MixedMethods
  include MixedMethods
  def self.included(klass)
    klass.extend MixedMethods
  end
  
  def hash_for_tem(data)
    Tem::CryptoAbi.hash_for_tem data
  end

  def self.load_ssl(ssl_key)
    return { :pubkey => AsymmetricKey.new(ssl_key, true, :pkcs1),
             :privkey => AsymmetricKey.new(ssl_key, false, :pkcs1) }
  end
  
  def self.generate_ssl_kp
    return Tem::CryptoAbi::AsymmetricKey.generate_ssl_kp
  end
  
  def self.generate_ssl_sk
    return Tem::CryptoAbi::SymmetricKey.generate_ssl_sk
  end

  # Wraps a TEM asymmetric key.
  class AsymmetricKey
    attr_reader :ssl_key
    
    def self.new_from_array(array)
      AsymmetricKey.new(OpenSSL::PKey::RSA.new(array[0]), *array[1..-1])      
    end
    
    def self.new_from_yaml_str(yaml_str)
      array = YAML.load yaml_str
      new_from_array array
    end
  
    def to_array
      [@ssl_key.to_pem, @is_public, @padding_type]
    end
    
    def to_yaml_str
      self.to_array.to_yaml.to_s
    end       
    
    # Generate an asymmetric OpenSSL key pair
    def self.generate_ssl_kp
      return OpenSSL::PKey::RSA.generate(2048, 65537)
    end
        
    def initialize(ssl_key, is_public, padding_type)
      @ssl_key = ssl_key
      @is_public = is_public ? true : false
      @padding_type = padding_type
      
      case padding_type
      when :oaep
        @padding_id = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING 
        @padding_bytes = 42
      when :pkcs1
        @padding_id = OpenSSL::PKey::RSA::PKCS1_PADDING
        @padding_bytes = 11
      else
        raise "Unknown padding type #{padding_type}\n"
      end
      
      @size = 0
      n = is_public ? @ssl_key.n : (@ssl_key.p * @ssl_key.q)
      while n != 0 do
        @size += 1
        n >>= 8
      end
    end
    
    def to_tem_key
      Tem::CryptoAbi.to_tem_key @ssl_key, (@is_public ? :public : :private)
    end
    
    def chug_data(data, in_size, &chug_block)
      output = data.class.new
      i = 0
      while i < data.length do
        block_size = (data.length - i < in_size) ? data.length - i : in_size
        if data.kind_of? String
          block = data[i...(i+block_size)]
        else 
          block = data[i...(i+block_size)].pack('C*')
        end
        o_block = yield block
        if data.kind_of? String
          output += o_block
        else
          output += o_block.unpack('C*')
        end
        i += block_size
      end
      return output
    end
    
    def encrypt_decrypt(data, in_size,  op)
      chug_data(data, in_size) { |block| @ssl_key.send op, block, @padding_id }    
    end
      
    def encrypt(data)
      encrypt_decrypt data, @size - @padding_bytes,
                      @is_public ? :public_encrypt : :private_encrypt      
    end
    
    def decrypt(data)
      encrypt_decrypt data, @size,
                      @is_public ? :public_decrypt : :private_decrypt      
    end
    
    def sign(data)
      data = data.pack 'C*' if data.respond_to? :pack
      # PKCS1-padding is forced in by openssl... sigh!
      out_data = @ssl_key.sign OpenSSL::Digest::SHA1.new, data
      data.respond_to?(:pack) ? out_data : out_data.unpack('C*')
    end
    
    def verify(data, signature)
      data = data.pack 'C*' if data.respond_to? :pack
      signature = signature.pack 'C*' if signature.respond_to? :pack
      # PKCS1-padding is forced in by openssl... sigh!
      @ssl_key.verify OpenSSL::Digest::SHA1.new, signature, data
    end
    
    def is_public?
      @is_public
    end
  end
  
  # Wraps a TEM symmetric key
  def SymmetricKey
    def initialize(ssl_key)
      @key = ssl_key
      @cipher = OpenSSL::Cipher::Cipher.new 'aes-128-ecb'
      @cipher.key = @key
      @cipher.iv = "\0" * 16
    end
    
    def encrypt(data)
    end
  
    def decrypt(data)
    end
  
    def sign(data)
    end
  
    def verify(data)
    end
  end
end
