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
    emit_proc = assemble do |p|
      # generate EK, compare with (0, 1)
      p.genkp :type => 0
      p.ldbc 1
      p.sub
      p.jne :to => :not_ok
      p.ldbc 0
      p.sub
      p.jne :to => :not_ok
      
      # generate and output random authorization for PrivEK
      p.ldbc 20
      p.dupn :n => 1
      p.outnew
      p.ldwc :privek_auth
      p.dupn :n => 2
      p.rnd
      p.outvb
      # set authorizations for PrivEK and PubkEK
      p.ldbc 0
      p.authk :auth => :privek_auth
      p.ldbc 1 # PubEK always has its initial authorization be all zeroes
      p.authk :auth => :pubek_auth
      p.halt
      
      # emitting didn't go well, return nothing and leave
      p.label :not_ok
      p.ldbc 0
      p.outnew
      p.halt
      
      p.label :privek_auth
      p.filler :ubyte, 20
      p.label :pubek_auth
      p.filler :ubyte, 20
      p.stack
      p.extra 8
    end
    
    r = execute emit_proc
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