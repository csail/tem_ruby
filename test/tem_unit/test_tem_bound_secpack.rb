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
        s.zeros :tem_ubyte, 20
        s.stack 4
    }

    sb = bound_sec.body
    secret_offset = (0...sb.length).find { |i| secret == sb[i, secret.length] }    
    assert secret_offset, 'The unbound secpack does not contain the secret.'

    bound_sec.bind pubk, :secret, :plain
    if yaml_roundtrip
      # same test, except the SECpack is serialized/deserialized
      yaml_bound_sec = bound_sec.to_yaml_str
      bound_sec = Tem::SecPack.new_from_yaml_str(yaml_bound_sec)
    end    
    result = @tem.execute bound_sec, keyd[:privk_id]
    assert_equal secret, result, 'TEM failed to decrypt secpack'

    sb = bound_sec.body
    assert !(0...sb.length).find { |i| secret == sb[i, secret.length] },
           'Secret found unencrypted in bound secpack'

    assert_equal 0, bound_sec.get_value(:plain, :tem_ushort),
                 'SecPack plaintext corrupted during binding'

    # HACK: cheating knowing that yaml_roundtrip will be false and true to
    #       test both set_value/get_value and set_bytes/get_bytes
    if yaml_roundtrip
      bound_sec.set_value :mess_place, :tem_ubyte,
                          bound_sec.get_value(:mess_place, :tem_ubyte) + 1
    else
      bytes = bound_sec.get_bytes(:mess_place, 4)
      bytes[0] += 1
      assert_equal 4, bytes.length, "get_bytes didn't find 4 bytes to mess with"
      bound_sec.set_bytes :mess_place, bytes      
    end
  
    assert_raise(RuntimeError, "secpack validation isn't working") do
      @tem.execute bound_sec
    end
  end
end

class TemBoundSecpackTest < TemTestCase
  include TemBoundSecpackTestCase    
  def test_bound_secpack
    _test_bound_secpack false
  end
end
