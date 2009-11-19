require 'test/tem_test_case.rb'

class TemMigrateTest < TemTestCase
  def _migrate_test_secret
    [0x31, 0x41, 0x59, 0x65, 0x35]
  end
  
  def _migrate_test_seclosure
    Tem::Assembler.assemble { |s|
      s.label :secret
      s.ldbc :const => _migrate_test_secret.length
      s.dupn :n => 1
      s.outnew
      s.outvlb :from => :dump_data
      s.halt
      s.label :dump_data
      s.data :tem_ubyte, _migrate_test_secret
      s.label :plain
    }
  end
  
  def test_migrate
    # Emit the TEM, bind the SECpack, and test it.
    privek_auth = @tem.emit
    sec = _migrate_test_seclosure
    sec.bind @tem.pubek, :secret, :plain
    assert_equal _migrate_test_secret, @tem.execute(sec),
                 'Migration test SECpack incorrect'
    
    # The migration target key pair.
    ekey = OpenSSL::PKey::RSA.generate(2048, 65537)
    privk = Tem::Key.new_from_ssl_key ekey
    pubk = Tem::Key.new_from_ssl_key ekey.public_key
    ecert2 = Tem::CA.new_ecert pubk.ssl_key
    migrated = @tem.migrate sec, ecert2
    
    authz = [0] * 20
    privk_id = @tem.tk_post_key privk, authz
    assert_equal _migrate_test_secret, @tem.execute(migrated, privk_id),
                 'Migrated SECpack executed incorrectly'
    @tem.release_key privk_id

    assert_equal _migrate_test_secret, @tem.execute(sec),
                 'Migration blew up original SECpack'
  end
end
