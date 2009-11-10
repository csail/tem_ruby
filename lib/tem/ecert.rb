require 'openssl'

module Tem::ECert
  # Writes an Endorsement Certificate to the TEM's tag.
  def set_ecert(ecert)
    set_tag ecert.to_der.unpack('C*')
  end
  
  # Retrieves the TEM's Endorsement Certificate.
  def endorsement_cert
    OpenSSL::X509::Certificate.new get_tag.pack('C*')
  end
  
  # Retrieves the certificate of the TEM's Manfacturer (CA).
  def manufacturer_cert
    Tem::CA.ca_cert
  end
  
  # Retrieves the TEM's Public Endorsement Key.
  def pubek
    Tem::Key.new_from_ssl_key endorsement_cert.public_key
  end
  
  # Drives a TEM though the emitting process.
  def emit
    emit_sec = assemble do |s|
      # Generate Endorsement Key pair, should end up in slots (0, 1).
      s.genkp :type => 0
      s.ldbc 1
      s.sub
      s.jne :to => :not_ok
      s.ldbc 0
      s.sub
      s.jne :to => :not_ok
      
      # Generate and output random authorization for PrivEK.
      s.ldbc 20
      s.dupn :n => 1
      s.outnew
      s.ldwc :privek_auth
      s.dupn :n => 2
      s.rnd
      s.outvb
      # Set authorizations for PrivEK and PubkEK.
      s.ldbc 0
      s.authk :auth => :privek_auth
      s.ldbc 1 # PubEK always has its initial authorization be all zeroes.
      s.authk :auth => :pubek_auth
      s.halt
      
      # Emitting didn't go well, return nothing and leave.
      s.label :not_ok
      s.ldbc 0
      s.outnew
      s.halt
      
      s.label :privek_auth
      s.zeros :tem_ubyte, 20
      s.label :pubek_auth
      s.zeros :tem_ubyte, 20
      s.stack 4
    end
    
    r = execute emit_sec
    if r.length == 0
      return nil
    else
      privk_auth = r[0...20]
      pubek_auth = (0...20).map {|i| 0}
      pubek = tk_read_key 1, pubek_auth
      tk_delete_key 1, pubek_auth      
      ecert = new_ecert pubek.ssl_key
      set_ecert ecert
      return { :privek_auth => privk_auth }
    end
  end
end
