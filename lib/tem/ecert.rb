require 'openssl'

module Tem::ECert
  # The key storing the Endorsement Certificate in the TEM's tag.
  def self.ecert_tag_key
    0x01
  end
  
  # The tag contents for an endorsement certificate.
  def self.ecert_tag(ecert)
    { ecert_tag_key => ecert.to_der.unpack('C*') }
  end
  
  # Retrieves the TEM's Endorsement Certificate.
  def endorsement_cert
    raw_cert = tag[Tem::ECert.ecert_tag_key].pack('C*')
    OpenSSL::X509::Certificate.new raw_cert
  end
  
  # Retrieves the certificate of the TEM's Manfacturer (CA).
  def manufacturer_cert
    Tem::CA.ca_cert
  end
  
  # Retrieves the TEM's Public Endorsement Key.
  def pubek
    Tem::Key.new_from_ssl_key endorsement_cert.public_key
  end  
end
