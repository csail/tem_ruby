require 'test/tem_test_case.rb'

require 'test/tem_unit/test_tem_bound_secpack.rb'
require 'test/tem_unit/test_tem_memory_compare.rb'


class TemOutputTest < TemTestCase
  include TemBoundSecpackTestCase
  include TemMemoryCompareTestCase
  
  
  def test_yaml_secpack
    # simple test to ensure that the body is preserved
    sec = @tem.assemble { |s|
      s.ldbc 10
      s.outnew
      s.ldwc 0x1234
      s.ldwc 0x5678
      s.dupn :n => 2
      s.add
      s.outw
      s.sub
      s.outw
      s.ldwc 0x0155
      s.ldwc 0x02AA
      s.mul
      s.outw
      s.ldwc 0x390C
      s.ldwc 0x00AA
      s.dupn :n => 2
      s.div
      s.outw
      s.mod
      s.outw
      s.halt
      s.stack 5
    }
    yaml_sec = sec.to_yaml_str
    sec2 = Tem::SecPack.new_from_yaml_str(yaml_sec)
    assert_equal sec.body, sec2.body,
                 'SECpack body corrupted during serialization'
    
    # re-run the memory test (reasonably large SECpack) to ensure that de-serialized SECpacks are equivalent to the originals
    _test_memory_copy_compare true
    # re-run the memory test (reasonably large SECpack) to ensure that serialization works on bound SECpacks
    _test_bound_secpack true
  end  
end
