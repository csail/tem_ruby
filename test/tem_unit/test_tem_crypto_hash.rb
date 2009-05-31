require 'test/tem_test_case'

class TemCryptoHashTest < TemTestCase
  def test_crypto_hash
    garbage1 = (0...8).map { |x| (31 * x * x + 5 * x + 3) % 256 }
    garbage2 = (0...11).map { |x| (69 * x * x + 62 * x + 10) % 256 }
    hash_size = 20
    
    sec = @tem.assemble { |s|
      s.ldwc hash_size * 3
      s.outnew
      s.mdfxb :size => garbage1.length, :from => :garbage1, :to => :hash_area
      s.outfxb :size => hash_size, :from => :hash_area
      s.mdfxb :size => garbage2.length, :from => :garbage2, :to => 0xFFFF
      s.ldwc garbage2.length
      s.ldwc :garbage2
      s.ldwc :hash_area
      s.mdvb
      s.outfxb :size => hash_size, :from => :hash_area
      s.halt
      s.label :garbage1
      s.data :tem_ubyte, garbage1
      s.label :garbage2
      s.data :tem_ubyte, garbage2
      s.label :hash_area
      s.zeros :tem_ubyte, hash_size
      s.stack 5
    }
    
    result = @tem.execute sec
    assert_equal [garbage1, garbage2, garbage2].map { |d| @tem.tem_hash d}.
                                                flatten,
                  result, 'cryptographic hashing isn\'t working well'
  end
end
