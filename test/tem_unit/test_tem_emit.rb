require 'test/tem_test_case.rb'

class TemEmitTest < TemTestCase
  def test_emit
    # try to emit
    er = @tem.emit
    assert er != nil, 'TEM emitting failed'
    
    # now verify that the private key is good and the authorization matches
    privek = @tem.tk_read_key 0, er[:privek_auth]
    assert((not privek.is_public?), 'TEM emission failed to produce a proper PrivEK')

    # verify that the public key can be read from the ECert
    pubek = @tem.pubek
    assert pubek.is_public?, 'TEM emission failed to produce a proper PubEK'

    # verify the PrivEK against the ECert
    ecert = @tem.endorsement_cert
    ecert.verify privek.ssl_key
    
    @tem.tk_delete_key 0, er[:privek_auth]
  end  
end
