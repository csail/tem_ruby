# Logic for SECpack migration.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'openssl'

# :nodoc: namespace
module Tem::Admin


# Logic for migrating SECpacks.
module Migrate
  # SEClosure that verifies the destination TEM's ECert.
  #
  # Args:
  #   key_ps_addr:: the PStore address used to store the TEM key's ID
  #   authz:: the authentication secret for the TEM's PrivEK 
  def self.ecert_verify_seclosure(key_ps_addr, authz)
    Tem::Assembler.assemble { |s|
      # TODO: some actual verification, jump to :failure if it doesn't work
      
      s.ldwc :const => :pubek        
      s.rdk
      s.authk :auth => :authz
      s.stw :to => :key_id
      s.pswrfxb :addr => :pstore_addr, :from => :key_id
      s.label :success
      s.ldbc :const => 1
      s.dupn :n => 1
      s.outnew
      s.outb
      s.halt
      
      s.label :failure
      s.ldbc :const => 1
      s.outnew
      s.ldbc :const => 0
      s.outb
      s.halt
      
      s.label :key_id
      s.zeros :tem_ps_value  # Will hold the ID of the loaded PubEK.
      
      s.label :secret
      s.label :authz  # The authentication key for the PrivEK.
      s.data :tem_ubyte, authz
      s.label :pstore_addr
      s.data :tem_ps_addr, key_ps_addr
      s.label :plain
      # ARG: the target TEM's public endorsement key.
      s.label :pubek
      s.zeros :tem_ubyte, 300
      # ARG: the target TEM's endorsement certificate.
      s.label :ecert
      s.stack 10
    }
  end
  
  # Blank version of the SEClosure that verifies the destination TEM's ECert.
  #
  # The returned SEClosure is not suitable for execution. Its encrypted bytes
  # should be replaced with the bytes from a SECpack generated with live data.
  def self.blank_ecert_verify_seclosure
    ecert_verify_seclosure [0] * Tem::Abi.tem_ps_addr_length,
                           [0] * Tem::Abi.tem_hash_length
  end  
  
  # SEClosure that migrates a SECpack.
  #
  # Args:
  #   key_ps_addr:: the PStore address used to store the TEM key's ID
  #   authz:: the authentication secret for the TEM's PrivEK 
  def self.migrate_seclosure(key_ps_addr, authz)
    Tem::Assembler.assemble { |s|
      s.ldbc :const => 0        # Authorize PrivEK.
      s.authk :auth => :authz
      s.dupn :n => 1             # Compute the size of the encrypted blob.
      s.ldw :from => :secpack_secret_size
      s.ldkel
      
      # Decrypt secpack.
      s.ldwc :const => :secpack_encrypted
      s.ldwc :const => :secpack_encrypted
      s.kdvb
      s.ldw :from => :secpack_secret_size  # Fail for wrong blob size.
      s.sub
      s.jnz :failure

      # Authorize target PubEK.
      s.psrdfxb :addr => :pstore_addr, :to => :key_id
      s.ldw :from => :key_id
      s.authk :auth => :authz
      
      s.dupn :n => 1  # Prepare output buffer.
      s.ldw :from => :secpack_secret_size
      s.ldkel
      s.outnew

      s.ldw :from => :secpack_secret_size  # Re-encrypt the blob.
      s.ldwc :const => :secpack_encrypted
      s.ldwc :const => -1
      s.kevb
      
      s.ldw :from => :key_id   # Clean up.
      s.relk
      s.ldbc :const => -1
      s.stw :to => :key_id
      s.pswrfxb :addr => :pstore_addr, :from => :key_id
      s.halt
      
      s.label :failure  # Communicate some failure.
      s.ldbc :const => 0
      s.outnew
      s.halt

      s.label :key_id
      s.zeros :tem_ps_value  # Will hold the ID of the loaded PubEK.
      
      s.label :secret
      s.label :authz  # The authentication key for the PrivEK.
      s.data :tem_ubyte, authz
      s.label :pstore_addr
      s.data :tem_ps_addr, key_ps_addr
      s.label :plain
      s.stack 20
      # ARG: the 'encrypted size' field in the SECpack header. 
      s.label :secpack_secret_size 
      s.zeros :tem_short, 1
      # ARG: the encrypted blob in the SECpack.
      s.label :secpack_encrypted
      s.zeros :tem_ubyte, 1
      s.label :secpack_encrypted_end
    }
  end
  
  # Blank version of the SEClosure that verifies the destination TEM's ECert.
  #
  # The returned SEClosure is not suitable for execution. Its encrypted bytes
  # should be replaced with the bytes from a SECpack generated with live data.
  def self.blank_migrate_seclosure
    migrate_seclosure [0] * Tem::Abi.tem_ps_addr_length,
                      [0] * Tem::Abi.tem_hash_length
  end  
  
  # The key storing the encrypted bytes of the ecert_verify SECpack in the
  # TEM's tag.
  def self.ecert_verify_bytes_tag_key
    0x11
  end
  
  # The key storing the encrypted bytes of the migrate SECpack in the TEM's tag.
  def self.migrate_bytes_tag_key
    0x12
  end
  
  # Data to be included in a TEM's tag to support migration.
  #
  # Returns a hash of tag key-values to be included in the TEM's tag during
  # emission.
  def self.tag_data(pubek, privek_authz)
    ps_addr = OpenSSL::Random.random_bytes(Tem::Abi.tem_ps_addr_length).
        unpack('C*')
    ev_sec = ecert_verify_seclosure ps_addr, privek_authz
    ev_sec.bind pubek
    
    m_sec = migrate_seclosure ps_addr, privek_authz
    m_sec.bind pubek
    
    {
      ecert_verify_bytes_tag_key => ev_sec.encrypted_data,
      migrate_bytes_tag_key => m_sec.encrypted_data
    }
  end
  
  # Recovers the migration-related SECpacks from the TEM's tag data.
  def self.seclosures_from_tag_data(tem)
    tag_data = tem.tag
    
    ecert_verify = blank_ecert_verify_seclosure
    ecert_verify.fake_bind
    ecert_verify.encrypted_data = tag_data[ecert_verify_bytes_tag_key]
    
    migrate = blank_migrate_seclosure
    migrate.fake_bind
    migrate.encrypted_data = tag_data[migrate_bytes_tag_key]
    
    { :ecert_verify => ecert_verify, :migrate => migrate }
  end
  
  # Migrates a SECpack to another TEM.
  #
  # Args:
  #   secpack:: the SECpack to be migrated
  #   ecert:: the Endorsement Certificate of the destination TEM
  #
  # Returns the migrated SECpack, or nil if the Endorsement Certificate was
  # rejected.
  def migrate(secpack, ecert)
    migrated = secpack.copy
    secpacks = Tem::Admin::Migrate.seclosures_from_tag_data self
    
    verify = secpacks[:ecert_verify]
    verify.set_bytes :pubek,
                     Tem::Key.new_from_ssl_key(ecert.public_key).to_tem_key
    return nil if execute(verify) != [1]
    
    migrate = secpacks[:migrate]
    migrate.set_value :secpack_secret_size, :tem_short, secpack.secret_bytes +
                      Tem::Abi.tem_hash_length
    migrate.set_bytes :secpack_encrypted, migrated.encrypted_data
    return nil unless new_encrypted_data = execute(migrate)
    migrated.encrypted_data = new_encrypted_data
    migrated
  end
end  # module Tem::Admin::Migrate

end  # namespace Tem::Admin
