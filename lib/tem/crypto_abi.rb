require 'openssl'
require 'digest'
require 'yaml'

module Tem::CryptoAbi
  include Tem::Abi
  
  # The methods that will be mixed into the TEM module
  module MixedMethods
    def load_tem_key_material(key, syms, buffer, offset)
      lengths = (0...syms.length).map do |i|
        read_tem_short buffer, offset + i * 2
      end
      offsets = [offset + syms.length * 2]
      syms.each_index { |i| offsets[i + 1] = offsets[i] + lengths[i] }
      syms.each_index do |i|
        key.send((syms[i].to_s + '=').to_sym,
                 read_tem_bignum(buffer, offsets[i], lengths[i]))
      end
    end
    
    # The length of a TEM symmetric key.
    def tem_symmetric_key_length
      16 # 128 bits
    end
            
    def read_tem_key(buffer, offset)
      key_type = read_tem_ubyte buffer, offset
      case key_type
      when 0x99
        key = buffer[offset, tem_symmetric_key_length]                
      when 0xAA, 0x55
        key = OpenSSL::PKey::RSA.new
        numbers = (key_type == 0xAA) ?
            read_tem_pubkey_numbers(buffer, offset + 1) :
            read_tem_privkey_numbers(buffer, offset + 1)
        numbers.each { |k, v| key.send :"#{k}=", v }
        if key_type == 0x55
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
        end
      else
        raise "Invalid key type #{'%02x' % key_type}"
      end
      return new_key_from_ssl(key, (key_type == 0xAA)) 
    end
    
    def to_tem_key(ssl_key, type)
      case type
      when :public
        to_tem_pubkey_numbers(:n => ssl_key.n, :e => ssl_key.e).unshift 0xAA          
      when :private
        to_tem_privkey_numbers(:dmp1 => ssl_key.dmp1, :dmq1 => ssl_key.dmq1,              
                               :iqmp => ssl_key.iqmp, :p => ssl_key.p,
                               :q => ssl_key.q).unshift 0x55          
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
