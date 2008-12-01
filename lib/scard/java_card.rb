class Tem::SCard::JavaCard
  attr_accessor :terminal
  
  def initialize(_terminal = nil)
    @terminal = _terminal
  end

  def select_applet(aid)
    result = @terminal.issue_apdu [0x00, 0xA4, 0x04, 0x00, aid.length, aid].flatten
    raise 'Failed to select applet' unless result == [0x90, 0x00]
  end
  
  def issue_apdu(apdu)
    @terminal.issue_apdu apdu
  end
  
  # returns the failure code of an operation (success would be 0x9000)
  # returns nil for success
  def failure_code(reply_apdu)
    status = reply_apdu[-2] * 256 + reply_apdu.length[-1]
    return (status == 0x9000) ? nil : status     
  end
  
  def reply_data(reply_apdu)
    return reply_apdu[0...-2]
  end
  
  def install_applet(cap_contents)
    raise "Not implemeted; it'd be nice though, right?"
  end
end
