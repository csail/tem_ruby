require 'test/tem_test_case.rb'


class VersionTest < TemTestCase
  def test_version
    version = @tem.fw_version
    assert version[:major].kind_of?(Numeric) &&
           version[:minor].kind_of?(Numeric),
           'Firmware version has wrong format'
  end
end
