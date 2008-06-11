# Victor Costan:
#    dropped because it wasn't hooked up to the rest of the code
#    preserved to move all the features into the new ca.rb / ecert.rb 

#@author: Jorge de la Garza (MIT '08), mongoose08@alum.mit.edu
#The Cert module contains methods for digesting a X.509 certificate into a tag
#for the TEM and to methods to reconstruct the certificate from the tag.  Methods
#to create some sample certificates are also included for convenience.

module Tem::Cert
  #@param key An OpenSSL::PKey instance that will be this cert's key and will be used to sign this cert
  #@returns a self-signed X.509 certificate that is supposed to be the TEM manufacturer's
  def self.create_issuer_cert(key)
    issuer_cert = OpenSSL::X509::Certificate.new
    issuer_cert.public_key = key.public_key
    issuer_dist_name = OpenSSL::X509::Name.new [['CN', 'TEM Manufacturer'], ['L', 'Cambridge'], ['ST', 'Massachusetts'],\
                         ['O', 'Trusted Execution Modules, Inc.'], ['OU', 'Certificates Division'], ['C', 'US']]
    issuer_cert.issuer = issuer_dist_name
    issuer_cert.subject = issuer_dist_name
    issuer_cert.not_before = Time.now
    issuer_cert.not_after = Time.now + (60 * 60 * 24 * 365.25) * 10
    issuer_cert.sign key, OpenSSL::Digest::SHA1.new
    return issuer_cert
  end
  
  
  #@param subject_key An OpenSSL::PKey instance that will be this cert's key
  #@param issuer_key An OpenSSL::Pkey instance that will be used to sign this cert (i.e. the issuer's/manufacturer's key)
  #@param issuer_cert The OpenSSL::X509::Certificate instance of the authority that issued this cert
  #@returns An OpenSSL::X509::Certificate instance issued by issuer_cert and signed by issuer_key
  def self.create_subject_cert(subject_key, issuer_key, issuer_cert)
    subject_cert = OpenSSL::X509::Certificate.new
    subject_cert.public_key = subject_key.public_key
    subject_cert.serial = Time.now.to_i   #no significance to this #, just a value for demonstration of purpose
    subject_dist_name = OpenSSL::X509::Name.new [['CN', 'TEM Device'], ['L', 'Cambridge'], ['ST', 'Massachusetts'],\
                         ['O', 'Trusted Execution Modules, Inc.'], ['OU', 'Certificates Division'], ['C', 'US']]
    subject_cert.issuer = issuer_cert.subject
    subject_cert.subject = subject_dist_name
    subject_cert.not_before = Time.now
    subject_cert.not_after = Time.now + (60 * 60 * 24 * 365.25) * 10
    subject_cert.sign issuer_key, OpenSSL::Digest::SHA1.new
    return subject_cert
  end
  
  
  #@param cert An OpenSSL::X509::Certificate instance
  #@returns The tag to write to the TEM as a byte array
  #The tag is 527 bytes long.  What the bytes encode is as follows:
  #    -Serial number   tag[0..3]
  #    -Not before date tag[4..7]
  #    -Not after date  tag[8..11]
  #    -Modulus         tag[12..267]
  #    -Public key exp  tag[268..270]
  #    -Signature       tag[271..526]
  def self.create_tag_from_cert(cert)
    tag_serial_num = Tem::CryptoAbi.to_tem_bignum(OpenSSL::BN.new(cert.serial.to_s))
    while tag_serial_num.length < 4
      tag_serial_num = [0] + tag_serial_num  #make sure array is 4 bytes
    end
    #The dates are encoded as the number of seconds since epoch (Jan 1, 1970 00:00:00 GMT)
    #TODO: check that dates are exactly 4 bytes, else throw an exception
    tag_not_before = Tem::CryptoAbi.to_tem_bignum(OpenSSL::BN.new(cert.not_before.to_i.to_s))
    tag_not_after = Tem::CryptoAbi.to_tem_bignum(OpenSSL::BN.new(cert.not_after.to_i.to_s))
    tag_modulus = Tem::CryptoAbi.to_tem_bignum(OpenSSL::BN.new(cert.public_key.n.to_s))
    #TODO: ensure that exponent is exactly three bytes, or come up with a safer way to encode it
    tag_public_exp = Tem::CryptoAbi.to_tem_bignum(OpenSSL::BN.new(cert.public_key.e.to_s))
    tag = [tag_serial_num, tag_not_before, tag_not_after, tag_modulus, tag_public_exp].flatten
    return tag
  end
  
  #@param tag The tag read from the TEM
  #@param issuer_cert The OpenSSL::X509::Certificate of the entity that issued the TEM's certificate
  #@returns The unsigned OpenSSL::X509::Certificate from which the tag was created.
  def self.create_cert_from_tag(tag, issuer_cert)
    cert = OpenSSL::X509::Certificate.new
    cert.public_key = Cert.extract_key(tag)
    cert.serial = Cert.extract_serial_num(tag)
    cert_name = OpenSSL::X509::Name.new [['CN', 'TEM Device'], ['L', 'Cambridge'], ['ST', 'Massachusetts'],\
                         ['O', 'Trusted Execution Modules, Inc.'], ['OU', 'Certificates Division'], ['C', 'US']]
    cert.issuer = issuer_cert.subject
    cert.subject = cert_name
    cert.not_before = Cert.extract_not_before(tag)
    cert.not_after = Cert.extract_not_after(tag)
    return cert
  end
  
  
  #returns a number
  def self.extract_serial_num(tag)
    serial_num_array = tag[0..3]
    serial_num = 0
    for i in (0..serial_num_array.length-1)
      serial_num = serial_num << 8
      serial_num += serial_num_array[i]
    end
    return serial_num
  end
  
  #returns a Time
  def self.extract_not_before(tag)
    time_array = tag[4..7]
    offset_in_sec = 0
    for i in (0..time_array.length-1)
      offset_in_sec = offset_in_sec << 8
      offset_in_sec += time_array[i]
    end
    return Time.at(offset_in_sec)
  end
  
  #returns a time
  def self.extract_not_after(tag)
    time_array = tag[8..11]
    offset_in_sec = 0
    for i in (0..time_array.length-1)
      offset_in_sec = offset_in_sec << 8
      offset_in_sec += time_array[i]
    end
    return Time.at(offset_in_sec)
  end
  
  #returns a OpenSSL::PKey::RSA public key
  def self.extract_key(tag)
    mod_array = tag[12..267]
    mod = 0
    for i in (0..mod_array.length-1)
      mod = mod << 8
      mod += mod_array[i]
    end
    exp_array = tag[268..271]
    exp = 0
    for i in (0..exp_array.length-1)
      exp = exp << 8
      exp += exp_array[i]
    end
    key = OpenSSL::PKey::RSA.new
    key.n = mod
    key.e = exp
    return key.public_key
  end
  
  
  #@param cert A signed OpenSSL::X509::Certificate instance
  #cert must be signed with sha1WithRSAEncryption algorithm
  #TODO: how to make this method compatible with any algorithm
  #@returns a byte array corresponding to the signature
  def self.extract_sig_from_cert(cert)
    str = 'Signature Algorithm: sha1WithRSAEncryption'
    text_sig = cert.to_text
    first_index = text_sig.index(str)
    text_sig = text_sig[first_index+1..-1]
    second_index = text_sig.index(str)
    sig_start_index = second_index+str.length + 1 #the 1 is for the newline character
    text_sig = text_sig[sig_start_index..-1]
    sig_array = []
    text_sig.each(':') {|byte| sig_array.push(byte.delete(':').hex)}
    return sig_array
  end  
end