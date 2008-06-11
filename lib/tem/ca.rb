require 'openssl'
require 'yaml'

# Certificate Authority (CA) functionality for TEM manufacturers
module Tem::CA
  # creates an Endorsement Certificate for a TEM's Public Endorsement Key
  def new_ecert(pubek)
    ca_cert = Tem::CA.ca_cert
    ca_key = Tem::CA.ca_key
    conf = Tem::CA.config
    
    dn = OpenSSL::X509::Name.new conf[:issuer].merge(conf[:subject]).to_a
    now = Time.now
    ecert = OpenSSL::X509::Certificate.new
    ecert.issuer = ca_cert.subject
    ecert.subject = dn
    ecert.not_before = now;
    ecert.not_after = now + conf[:ecert_validity_days] * 60 * 60 * 24;
    ecert.public_key = pubek
    ecert.version = 2
    cf = OpenSSL::X509::ExtensionFactory.new
    cf.subject_certificate = ecert 
    cf.issuer_certificate = ca_cert
    ecert.add_extension cf.create_extension("basicConstraints", "CA:true", true)
    ecert.add_extension cf.create_extension("authorityKeyIdentifier", "keyid,issuer")    
    ecert.add_extension cf.create_extension("keyUsage", "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign")
    ecert.add_extension cf.create_extension("extendedKeyUsage", "serverAuth,clientAuth,codeSigning,emailProtection,timeStamping,msCodeInd,msCodeCom,msCTLSign,msSGC,msEFS,nsSGC")
    ecert.add_extension cf.create_extension("nsCertType", "client,server,email,objsign,sslCA,emailCA,objCA")
    ecert.add_extension cf.create_extension("subjectKeyIdentifier", "hash")
    ecert.sign ca_key, OpenSSL::Digest::SHA1.new
    
    return ecert
  end
  
  @@dev_dir = File.join(File.dirname(__FILE__), "..", "..", "dev_ca")

  # retrieves the TEM CA configuration 
  def self.config
    cpath = Tem::Hive.path_to 'ca/config.yml'
    cpath = File.join(@@dev_dir, 'config.yml') unless File.exists? cpath

    # try to open it in the base folder
    scaffold_config unless File.exists? cpath
    return File.open(cpath, 'r') { |f| YAML.load f } 
  end
  
  # retrieves the TEM CA certificate
  def self.ca_cert
    cpath = Tem::Hive.path_to 'ca/ca_cert.pem'
    cpath = File.join(@@dev_dir, 'ca_cert.pem') unless File.exists? cpath
    return OpenSSL::X509::Certificate.new(File.open(cpath, 'r') { |f| f.read })
  end
  
  # retrieves the TEM CA key pair (needed for signing)
  def self.ca_key
    cpath = Tem::Hive.path_to 'ca/ca_key.pem'
    cpath = File.join(@@dev_dir, 'ca_key.pem') unless File.exists? cpath
    return OpenSSL::PKey::RSA.new(File.open(cpath, 'r') { |f| f.read })
  end

  # scaffolds the structures needed for a TEM CA
  def self.scaffold_ca
    conf = config
    
    # generate and write key
    ca_key = Tem::CryptoAbi.generate_ssl_kp
    key_path = Tem::Hive.create 'ca/ca_key.pem'
    File.open(key_path, 'w') { |f| f.write ca_key.to_pem }
    
    # create the CA certificate
    dn = OpenSSL::X509::Name.new conf[:issuer].to_a
    now = Time.now
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = dn
    cert.not_before = now;
    cert.not_after = now + conf[:ca_validity_days] * 60 * 60 * 24;
    cert.public_key = ca_key.public_key
    cert.version = 2
    cf = OpenSSL::X509::ExtensionFactory.new
    cf.subject_certificate = cf.issuer_certificate = cert
    cert.add_extension cf.create_extension("basicConstraints", "CA:true", true)
    cert.add_extension cf.create_extension("authorityKeyIdentifier", "keyid,issuer")    
    cert.add_extension cf.create_extension("keyUsage", "cRLSign,keyCertSign")
    cert.add_extension cf.create_extension("nsCertType", "emailCA,sslCA")
    cert.add_extension cf.create_extension("subjectKeyIdentifier", "hash")
    cert.sign ca_key, OpenSSL::Digest::SHA1.new    
    
    # write the CA certificate
    cert_path = Tem::Hive.create 'ca/ca_cert.pem'
    File.open(cert_path, 'w') { |f| f.write cert.to_pem }
    cert_path = Tem::Hive.create 'ca/ca_cert.cer'
    File.open(cert_path, 'wb') { |f| f.write cert.to_der }
  end
  
  # scaffolds a TEM CA configuration
  def self.scaffold_config
    def_config = {
      :issuer => {
        'C' => 'US', 'ST' => 'Massachusetts', 'L' => 'Cambridge',
        'O' => 'Massachusetts Insitute of Technology',
        'OU' => 'Computer Science and Artificial Intelligence Laboratory',
        'CN' => 'Trusted Execution Module Development CA'
      },
      :subject => {
        'CN' => 'Trusted Execution Module DevChip'
      },
      :ca_validity_days => 3652,
      :ecert_validity_days => 365 * 2,
    } 
    
    cpath = Tem::Hive.create 'ca/config.yml'
    File.open(cpath, 'w') { |f| YAML.dump def_config, f }
  end
end