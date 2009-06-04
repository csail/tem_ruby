require 'tem_ruby'
require 'test/unit'

class AutoConfTest < Test::Unit::TestCase
  def test_autoconf_reconnect
    Tem.auto_conf
    $tem.activate
    $tem.disconnect
    assert_nil $tem, "$tem not reset after disconnect call"
    Tem.auto_conf
    assert_not_nil $tem.stat_buffers,
                   "Stating the TEM buffers failed after 2 auto_confs"
    $tem.disconnect
  end
end
