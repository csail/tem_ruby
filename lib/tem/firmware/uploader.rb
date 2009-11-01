# TEM firmware installation and update.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Firmware


# Installs and updates
module Uploader
  # Path to the JavaCard CAP file containing the firmware.
  #
  # CAP updates can be downloaded directly from the URL below. However, it's
  # recommended to obtain them by installing a new version of the tem_ruby gem.
  # The gem is only tested with the firmware bundled with it.
  #
  # Update URL: http://rubyforge.org/frs/?group_id=6431
  def self.cap_file
    File.join File.dirname(__FILE__), 'tc.cap'
  end
  
  @applet_aid = nil
  # The AID for the firmware's JavaCard applet.
  def self.applet_aid
    # Cache expensive operation of unzipping the CAP file.
    return @applet_aid if @applet_aid
    
    cap_data = Smartcard::Gp::CapLoader.load_cap cap_file
    @applet_aid = Smartcard::Gp::CapLoader.parse_applets(cap_data).first[:aid]
  end
  
  # Uploads the firmware CAP file, removing any old version.
  #
  # Note that uploading a new version wipes the firmware's data completely, so
  # the TEM will have to be re-emitted, and will have a different endorsement
  # key.
  def self.upload_cap(transport)
    class <<transport
      include Smartcard::Gp::GpCardMixin
    end
    transport.install_applet cap_file
  end
  
  
end  # module Tem::Firmware::Uploader

end  # namespace Tem::Firmware
