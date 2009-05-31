require 'test/tem_test_case'

module TemBoundSecpackTestCase
  # This is also called from TemYamlSecpackTest.
  def _test_bound_secpack(yaml_roundtrip = false)
    keyd = @tem.tk_gen_key
    pubk = @tem.tk_read_key keyd[:pubk_id], keyd[:authz]
    
    secret = (0...16).map { |i| (99 * i * i + 51 * i + 33) % 256 }
    bound_sec = @tem.assemble { |s|
        s.ldbc secret.length
        s.outnew
        s.label :mess_place
        s.outfxb :size => secret.length, :from => :secret
        s.halt
        s.label :secret
        s.data :tem_ubyte, secret
        # Make sure the zero_bytes optimization doesn't screw things up.
        s.zeros :tem_ubyte, 60
        s.label :plain
        s.stack 4
    }

    sb = bound_sec.body
    secret_found = false
    0.upto(sb.length - 1) { |i| if secret == sb[i, secret.length] then secret_found = true; break; end }
    assert secret_found, 'test_bound_secpack needs rethinking: the unbound secpack does not contain the secret'

    bound_sec.bind pubk, :secret, :plain
    if yaml_roundtrip
      # same test, except the SECpack is serialized/deserialized
      yaml_bound_sec = bound_sec.to_yaml_str
      bound_sec = Tem::SecPack.new_from_yaml_str(yaml_bound_sec)
    end    
    result = @tem.execute bound_sec, keyd[:privk_id]
    assert_equal secret, result, 'TEM failed to decrypt secpack'

    sb = bound_sec.body
    0.upto(sb.length - 1) { |i| assert_not_equal secret, sb[i, secret.length], 'secret found unencrypted in bound secpack' }

    bound_sec.body[bound_sec.label_address(:mess_place)] += 1
    assert_raise(RuntimeError, 'secpack validation isn\'t working') { @tem.execute bound_sec }
  end  
end

class TemBoundSecpackTest < TemTestCase
  include TemBoundSecpackTestCase    
  def test_bound_secpack
    _test_bound_secpack false
  end
end
