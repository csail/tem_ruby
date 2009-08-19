require 'test/tem_test_case.rb'

class TemAluTest < TemTestCase
  def test_alu
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
    result = @tem.execute sec
    assert_equal [0x68, 0xAC, 0xBB, 0xBC, 0x8C, 0x72, 0x00, 0x55, 0x00, 0x9A],
                  result, 'the ALU isn\'t working well'
  end
end
