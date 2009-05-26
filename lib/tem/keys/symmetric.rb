# :nodoc: namespace
module Tem::Keys

# Wraps a TEM symmetric key, e.g. an AES key.
class Symmetric < Tem::Key
  @@cipher_mode = 'ECB'
  
  # Generates a new symmetric key.
  def self.generate
    cipher = OpenSSL::Cipher::AES128.new @@cipher_mode
    key = cipher.random_key
    self.new key
  end
  
  # Creates a new symmetric key based on an OpenSSL Cipher instance, augmented
  # with a key accessor.
  def initialize(ssl_key)
    super ssl_key
    @key = ssl_key.key
    @cipher_class = ssl_key.class
  end
  public_class_method :new

  def encrypt_or_decrypt(data, do_encrypt)
    cipher = @cipher_class.new @@cipher_mode
    do_encrypt ? cipher.encrypt : cipher.decrypt
    cipher.key = @key
    cipher.iv = "\0" * 16
    
  end
  
  def encrypt(data)
    cipher.encrypt_or_decrypt data, true
  end

  def decrypt(data)
    cipher.encrypt_or_decrypt data, false
  end

  def sign(data)
  end

  def verify(data)
  end
end

end  # namespace Tem::Keys
