require 'test/tem_test_case.rb'

class TemEmitTest < TemTestCase
  def test_emit
    # Try to emit the TEM.
    privek_auth = @tem.emit
    assert privek_auth != nil, 'TEM emitting failed'
    
    # Verify that the private key is good and the authorization matches.
    privek = @tem.tk_read_key 0, privek_auth
    assert((not privek.is_public?),
           'TEM emission failed to produce a proper PrivEK')

    # Verify that the public key can be read from the ECert.
    pubek = @tem.pubek
    assert pubek.is_public?, 'TEM emission failed to produce a proper PubEK'

    # Verify the PrivEK against the ECert.
    ecert = @tem.endorsement_cert
    ecert.verify privek.ssl_key
  end
end
