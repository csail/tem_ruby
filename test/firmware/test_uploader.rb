require 'tem_ruby'

require 'test/unit'


class UploaderTest < Test::Unit::TestCase
  Uploader = Tem::Firmware::Uploader
    
  def test_cap_file
    file = Uploader.cap_file
    assert file, "Cap_file returned a blank"
    
    assert Smartcard::Gp::CapLoader.load_cap(file), "Couldn't load CAP file" 
  end

  def test_applet_aid
    assert_equal [0x19, 0x83, 0x12, 0x29, 0x10, 0xBA, 0xBE], Uploader.applet_aid
  end
  
  def test_fw_version
    assert_equal({:major => 1, :minor => 15}, Uploader.fw_version)
  end
  
  def test_upload
    transport = Smartcard::Iso.auto_transport
    Uploader.upload_cap transport
    
    tem = Tem::Session.new transport
    assert_equal Uploader.fw_version, tem.fw_version,
                 'TEM firmware was not updated to current version'
    assert tem.activate, "Activation failed (old TEM firmware was not replaced)"
  end
end
