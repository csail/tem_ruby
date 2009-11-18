# Logic for the TEM emission process.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Admin


# Logic for the TEM emission process.
module Emit
  # The SEClosure that performs key generation for the TEM.
  def self.emit_keygen_seclosure
    Tem::Assembler.assemble { |s|
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
    }
  end
  
  # Performs the key generation step of the TEM emitting process.
  #
  # Args:
  #   tem:: session to the TEM that will be emitted
  #
  # Returns nil if key generation fails. In case of success, a hash with the
  # following keys is returned.
  #   :pubek:: the public Endorsement Key (PubEK) -- not stored on the TEM
  #   :privek_auth:: the authentication key for the private Endorsement Key
  #                  (PrivEK), which will always be stored on the chip
  def self.emit_keygen(tem)
    sec = emit_keygen_seclosure
    r = tem.execute sec
    return nil if r.empty?
    
    privek_auth = r[0...20]
    pubek_auth = (0...20).map {|i| 0}
    pubek = tem.tk_read_key 1, pubek_auth
    tem.tk_delete_key 1, pubek_auth
    { :privek_auth => privek_auth, :pubek => pubek }
  end
  
  # Drives a TEM though the emit process.
  #  
  # Args:
  #   tem:: session to the TEM that will be emitted.
  #
  # Returns nil if the emit process fails (most likely, the TEM was already
  # emitted). If the process completes, a hash with the following keys is
  # returned.
  #   :privek_auth:: the authorization token for the private Endorsement Key
  #                  (PrivEK) -- this value should be handled with care
  def self.emit(tem)
    tag = {}

    return nil unless key_data = emit_keygen(tem)
    
    # Build the Endorsement Certificate.
    ecert = Tem::CA.new_ecert key_data[:pubek].ssl_key
    tag.merge! Tem::ECert.ecert_tag ecert

    # Build administrative SECpacks.
    tag.merge! Tem::Admin::Migrate.tag_data key_data[:pubek],
                                            key_data[:privek_auth]
    
    tem.set_tag tag
    key_data
  end

  # Emits the TEM.
  #
  # Returns nil if the emit process fails (most likely, the TEM was already
  # emitted). If the process completes, it returns the authorization token for
  # the private Endorsement Key (PrivEK). This value is very sensitive and its
  # disclosure will compromise the TEM.
  def emit
    emit_data = Tem::Admin::Emit.emit self
    emit_data and emit_data[:privek_auth]
  end
end  # module Tem::Admin::Emit

end  # namespace Tem::Admin
