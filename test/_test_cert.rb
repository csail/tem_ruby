# Victor Costan:
#    dropped because it wasn't hooked up to the rest of the code
#    preserved to move all the features into the new ca.rb / ecert.rb

require 'tem_ruby'
require 'test/unit'
require 'openssl'

# Integration work by Victor Costan 


#Author: Jorge de la Garza (MIT '08), mongoose08@alum.mit.edu
#This unit test does the following:
#1. Makes issuer's (manufacturer's) X.509 certificate, which is self-signed.
#2. Makes subject's (TEM's) X.509 certificate, which is signed with the issuers private key.
#3. Constructs the TEMTag from the subject's:
#    -Serial number   (4 bytes)
#    -Not before date (4 bytes)
#    -Not after date  (4 bytes)
#    -Modulus         (256 bytes)
#    -Public key exp  (3 bytes)
#    -Signature       (256 bytes)
#4.  Sets the TEMTag on the TEM
#5.  Reads back the TEMTag
#6.  Constructs a new X.509 certificate from the TEMTag and asserts that this is equal to the original certificate

class CertTest < Test::Unit::TestCase
  def setup
    @terminal = Tem::SCard::JCOPRemoteTerminal.new
    unless @terminal.connect
      @terminal.disconnect
      @terminal = Tem::SCard::PCSCTerminal.new
      @terminal.connect
    end
    @javacard = Tem::SCard::JavaCard.new(@terminal)
    @tem = Tem::Session.new(@javacard)
    
    @tem.kill
    @tem.activate
    
    
  end
  
  def teardown
    @terminal.disconnect unless @terminal.nil?
  end
  
  def test_cert
    #Create issuer's (manufacturer's) certificate
    issuer_key = OpenSSL::PKey::RSA.new 2048, 0x10001
    issuer_cert = Tem::Cert.create_issuer_cert(issuer_key)
    
    #Create subject's (TEM's) certificate
    subject_key = OpenSSL::PKey::RSA.new 2048, 0x10001
    subject_cert = Tem::Cert.create_subject_cert(subject_key, issuer_key, issuer_cert)
    
    #Create the tag that will go on the TEM from it's certificate
    written_tag = Tem::Cert.create_tag_from_cert(subject_cert)
    
    #Set the tag on the TEM, assert that tag read = tag written
    @tem.set_tag(written_tag)
    read_tag = @tem.get_tag[2..-1] #chop off first two bytes, TEM puts firmware version on front of written tag
    assert_equal written_tag, read_tag, 'error in posted tag data'
    
    #Now reconstruct original certificate from tag data
    read_cert = Tem::Cert.create_cert_from_tag(read_tag, issuer_cert)
    read_cert.sign issuer_key, OpenSSL::Digest::SHA1.new
    
    assert_equal Tem::Cert.extract_sig_from_cert(subject_cert), Tem::Cert.extract_sig_from_cert(read_cert), 'signatures do not match'
    #If the signature of the original certificate matches the signature of the reconstructed certificate,
    #we can be pretty much certain that the certificates are identical
    
    #TODO: PROBLEM:
    #There is no way to set the signature to a known value.
    #The only way to set the signature is to sign the certificate, and only the issuer (manufacturer) can do this.
    #This means that the manufacturer has to be contacted every time the user wants to verify the TEM's certificate,
    #and this may not be practical.
    
    
  end  
end