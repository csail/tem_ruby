require 'pp'

class Tem::SCard::PCSCTerminal
  include Smartcard
  
  @@xmit_iorequest = {
    Smartcard::PCSC::PROTOCOL_T0 => Smartcard::PCSC::IOREQUEST_T0,
    Smartcard::PCSC::PROTOCOL_T1 => Smartcard::PCSC::IOREQUEST_T1,
  }
  
  def initialize
    @context = nil
    @readers = nil
    @card = nil
  end
  
  def connect
    begin
      @context = PCSC::Context.new(PCSC::SCOPE_SYSTEM) if @context.nil?
      
      # get the first reader
      @readers = @context.list_readers nil
      @reader_name = @readers.first
      
      # get the reader's status
      reader_states = PCSC::ReaderStates.new(1)
      reader_states.set_reader_name_of!(0, @reader_name)
      reader_states.set_current_state_of!(0, PCSC::STATE_UNKNOWN)
      @context.get_status_change reader_states, 100
      reader_states.acknowledge_events!
      
      # prompt for card insertion unless that already happened
      if (reader_states.current_state_of(0) & PCSC::STATE_PRESENT) == 0
        puts "Please insert TEM card in reader #{@reader_name}\n"
        while (reader_states.current_state_of(0) & PCSC::STATE_PRESENT) == 0 do
          @context.get_status_change reader_states, PCSC::INFINITE_TIMEOUT
          reader_states.acknowledge_events!
        end
        puts "Card detected\n"
      end
      
      # connect to card
      @card = PCSC::Card.new(@context, @reader_name, PCSC::SHARE_EXCLUSIVE, PCSC::PROTOCOL_ANY)
      
      # build the transmit / receive IoRequests
      status = @card.status
      @xmit_ioreq = @@xmit_iorequest[status[:protocol]]
      if RUBY_PLATFORM =~ /win/ and (not RUBY_PLATFORM =~ /darwin/)
        @recv_ioreq = nil
      else
        @recv_ioreq = PCSC::IoRequest.new
      end
    rescue
      return false
    end
  end
  
  def to_s
    "#<PC/SC Terminal: disconnected>" if @card.nil?
    "#<PC/SC Terminal: #{@reader_name}>"
  end
  
  def disconnect
    unless @card.nil?
      @card.disconnect PCSC::DISPOSITION_LEAVE unless @card.nil?
      @card = nil
    end
    unless @context.nil?
      @context.release
      @context = nil
    end
  end
  
  def issue_apdu(apdu)
    xmit_apdu_string = apdu.map { |byte| byte.chr }.join('')
    result_string = @card.transmit xmit_apdu_string, @xmit_ioreq, @recv_ioreq
    return (0...(result_string.length)).map { |i| result_string[i].to_i }
  end  
end

# for compatibility with old source code
class Tem::SCard::Terminal < Tem::SCard::PCSCTerminal
end