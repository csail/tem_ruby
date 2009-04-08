# :nodoc: namespace
module Tem::Transport
  
# Module intended to be mixed into transport implementations to mediate between
# a high level format for Javacard-specific APDUs and the wire-level APDU 
# request and response formats.
#
# The mix-in calls exchange_apdu in the transport implementation. It supplies
# the APDU data as an array of integers between 0 and 255, and expects a
# response in the same format.
module JavaCardMixin
  # Selects a Javacard applet.
  def select_applet(applet_id)
    applet_apdu! :ins => 0xA4, :p1 => 0x04, :p2 => 0x00, :data => applet_id
  end
  
  # APDU exchange with the JavaCard applet, raising an exception if the return
  # code is not success (0x9000).
  #
  # :call_seq:
  #   transport.applet_apdu!(apdu_data) -> array
  #
  # The apdu_data should be in the format expected by
  # JavaCardMixin#serialize_apdu. Returns the response data, if the response
  # status indicates success (0x9000). Otherwise, raises an exeception.
  def applet_apdu!(apdu_data)
    response = self.applet_apdu apdu_data
    return response[:data] if response[:status] == 0x9000
    raise "JavaCard response has error status 0x#{'%04x' % response[:status]}"
  end

  # Performs an APDU exchange with the JavaCard applet.
  #
  # :call-seq:
  #   transport.applet_apdu(apdu_data) -> hash
  #
  # The apdu_data should be in the format expected by
  # JavaCardMixin#serialize_apdu. The response will be as specified in
  # JavaCardMixin#deserialize_response.
  def applet_apdu(apdu_data)
    apdu = Tem::Transport::JavaCardMixin.serialize_apdu apdu_data
    response = self.exchange_apdu apdu
    JavaCardMixin.deserialize_response response
  end
  
  # Serializes an APDU for wire transmission.
  #
  # :call-seq:
  #   transport.wire_apdu(apdu_data) -> array
  #
  # The following keys are recognized in the APDU hash:
  #   cla:: the CLA byte in the APDU (optional, defaults to 0) 
  #   ins:: the INS byte in the APDU -- the first byte seen by a JavaCard applet
  #   p:: 
  #   p1, p2:: the P1 and P2 bytes in the APDU (optional, both default to 0)
  #   data:: the extra data in the APDU (optional, defaults to nothing)
  def self.serialize_apdu(apdu_data)
    raise 'Unspecified INS in apdu_data' unless apdu_data[:ins]
    apdu = [ apdu_data[:cla] || 0, apdu_data[:ins] ]
    if apdu_data[:p12]
      unless apdu_data[:p12].length == 2
        raise "Malformed P1,P2 - #{apdu_data[:p12]}"
      end
      apdu += apdu_data[:p12]
    else
      apdu << (apdu_data[:p1] || 0)
      apdu << (apdu_data[:p2] || 0)
    end
    if apdu_data[:data]
      apdu << apdu_data[:data].length
      apdu += apdu_data[:data]
    else
      apdu << 0
    end
    apdu
  end
  
  # De-serializes a JavaCard response APDU.
  # 
  # :call-seq:
  #   transport.deserialize_response(response) -> hash
  #
  # The response contains the following keys:
  #   status:: the 2-byte status code (e.g. 0x9000 is OK)
  #   data:: the additional data in the response
  def self.deserialize_response(response)
    { :status => response[-2] * 256 + response[-1], :data => response[0...-2] }
  end
  
  # Installs a JavaCard applet on the JavaCard.
  #
  # This would be really, really nice to have. Sadly, it's a far away TBD right
  # now.
  def install_applet(cap_contents)
    raise "Not implemeted; it'd be nice though, right?"
  end
end  # module Tem

end  # module Tem::Transport