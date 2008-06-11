require 'pp'

class Tem::Session
  include Tem::Abi
  include Tem::Buffers
  include Tem::CA
  include Tem::CryptoAbi
  include Tem::ECert
  include Tem::Keys
  include Tem::Lifecycle
  include Tem::SeClosures
  include Tem::Tag
  include Tem::Toolkit
  
  @@aid = [0x19, 0x83, 0x12, 0x29, 0x10, 0xBA, 0xBE]
  
  def initialize(javacard)
    @card = javacard
    @card.select_applet(@@aid)
  end
  
  def disconnect
    # TODO: deselect applet, reset card
    @card = nil
  end
  
  def issue_apdu(apdu)
    @card.issue_apdu apdu
  end
  
  def failure_code(reply_apdu)
    @card.failure_code reply_apdu
  end
  
  def reply_data(reply_apdu)
    @card.reply_data reply_apdu
  end
  
  def tem_error(response)
    fcode = failure_code response
    raise "TEM returned error 0x#{'%04x' % fcode} while processing the request"
  end
  
  def tem_secpack_error(response)
    raise "TEM refused the SECpack"
  end
end
