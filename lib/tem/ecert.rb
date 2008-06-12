require 'openssl'

module Tem::ECert
  # writes an Endorsement Certificate to the TEM's tag
  def set_ecert(ecert)
    set_tag ecert.to_der.unpack('C*')
  end
  
  # retrieves the TEM's Endorsement Certificate
  def endorsement_cert
    OpenSSL::X509::Certificate.new get_tag[2..-1].pack('C*')
  end
  
  # retrieves the certificate of the TEM's Manfacturer (CA)
  def manufacturer_cert
    Tem::CA.ca_cert
  end
  
  # retrieves the TEM's Public Endorsement Key
  def pubek
    new_key_from_ssl endorsement_cert.public_key, true
  end
  
  # emits a TEM
  def emit
    emit_sec = assemble do |s|
      # generate EK, compare with (0, 1)
      s.genkp :type => 0
      s.ldbc 1
      s.sub
      s.jne :to => :not_ok
      s.ldbc 0
      s.sub
      s.jne :to => :not_ok
      
      # generate and output random authorization for PrivEK
      s.ldbc 20
      s.dupn :n => 1
      s.outnew
      s.ldwc :privek_auth
      s.dupn :n => 2
      s.rnd
      s.outvb
      # set authorizations for PrivEK and PubkEK
      s.ldbc 0
      s.authk :auth => :privek_auth
      s.ldbc 1 # PubEK always has its initial authorization be all zeroes
      s.authk :auth => :pubek_auth
      s.halt
      
      # emitting didn't go well, return nothing and leave
      s.label :not_ok
      s.ldbc 0
      s.outnew
      s.halt
      
      s.label :privek_auth
      s.filler :ubyte, 20
      s.label :pubek_auth
      s.filler :ubyte, 20
      s.stack
      s.extra 8
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