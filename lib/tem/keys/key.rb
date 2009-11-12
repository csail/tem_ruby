# Superclass for Ruby implementations of the TEM's key operations.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT


# Base class for the TEM keys.
#
# This class consists of stubs describing the interface implemented by
# subclasses.
class Tem::Key
  # The OpenSSL key wrapped by this TEM key.
  attr_reader :ssl_key
  
  # Creates a new key based on an OpenSSL key.
  def initialize(ssl_key)
    @ssl_key = ssl_key
  end
  # This class should not be instantiated directly.
  private_class_method :new
  
  # Serializes this key to the TEM ABI format.
  def to_tem_key
    Tem::Abi.to_tem_key self
  end
  
  # Encrypts a block of data into a TEM-friendly format.
  def encrypt(data)
    raise "TEM Key class #{self.class.name} didn't implement encrypt"
  end

  def decrypt(data)
    raise "TEM Key class #{self.class.name} didn't implement decrypt"
  end

  def sign(data)
    raise "TEM Key class #{self.class.name} didn't implement sign"
  end

  def verify(data)
    raise "TEM Key class #{self.class.name} didn't implement verify"
  end

  # Creates a new TEM key wrapper from a SSL key
  def self.new_from_ssl_key(ssl_key)
    if ssl_key.kind_of? OpenSSL::PKey::PKey
      Tem::Keys::Asymmetric.new ssl_key
    elsif ssl_key.kind_of? OpenSSL::Cipher or ssl_key.kind_of? String
      Tem::Keys::Symmetric.new ssl_key
    else
      raise "Can't handle keys of class #{ssl_key.class}"
    end
  end
end  # class Tem::Key
