# :nodoc: namespace
module Tem::Keys

# Wraps a TEM asymmetric key, e.g. an RSA key.
class Asymmetric < Tem::Key  
  def self.new_from_array(array)
    self.new(OpenSSL::PKey::RSA.new(array[0]), *array[1..-1])      
  end
  
  def self.new_from_yaml_str(yaml_str)
    array = YAML.load yaml_str
    new_from_array array
  end

  def to_array
    [@ssl_key.to_pem, @padding_type]
  end
  
  def to_yaml_str
    self.to_array.to_yaml.to_s
  end       
  
  # Generate a pair of asymmetric keys.
  def self.generate_pair
    ssl_key = OpenSSL::PKey::RSA.generate(2048, 65537)
    new_pair_from_ssl_key ssl_key
  end
  
  # Creates a pair of asymmetric keys wrapping an OpenSSL private key.
  def self.new_pair_from_ssl_key(ssl_key)
    { :public => Tem::Keys::Asymmetric.new(ssl_key.public_key),
      :private => Tem::Keys::Asymmetric.new(ssl_key) }
  end
      
  def initialize(ssl_key, padding_type = :pkcs1)
    super ssl_key
    @is_public = !ssl_key.d
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
    n = @is_public ? @ssl_key.n : (@ssl_key.p * @ssl_key.q)
    while n != 0 do
      @size += 1
      n >>= 8
    end
  end
  public_class_method :new
    
  def is_public?
    @is_public
  end
  
  def encrypt(data)
    encrypt_or_decrypt data, @size - @padding_bytes,
                       @is_public ? :public_encrypt : :private_encrypt      
  end
  
  def decrypt(data)
    encrypt_or_decrypt data, @size,
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

  def encrypt_or_decrypt(data, in_size,  op)
    chug_data(data, in_size) { |block| @ssl_key.send op, block, @padding_id }    
  end
  private :encrypt_or_decrypt

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
  private :chug_data
end

end  # namespace Tem::Keys