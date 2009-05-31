require 'test/tem_test_case'

class TemCryptoRandomTest < TemTestCase
  def test_crypto_random
    sec = @tem.assemble { |s|
      s.ldbc 16
      s.outnew
      s.ldbc 8
      s.dupn :n => 1
      s.ldwc :rnd_area
      s.dupn :n => 2
      s.rnd       
      s.outvb
      s.ldbc(-1)
      s.rnd
      s.halt
      s.label :rnd_area
      s.zeros :tem_ubyte, 8
      s.stack 5
    }
    
    result = @tem.execute sec
    assert_equal 16, result.length, 'monotonic counters aren\'t working well'    
  end
end
