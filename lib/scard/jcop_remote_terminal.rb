require 'socket'
class Tem::SCard::JCOPRemoteTerminal    
  def initialize(remote_host = 'localhost', remote_port = 8050)
    @remote_host = remote_host
    @remote_port = remote_port
    @sockaddr = Socket.pack_sockaddr_in(@remote_port, @remote_host)
    @socket = nil
  end
  
  def send_message(payload, message_type = 1, node_address = 0)
    @socket.send [message_type, node_address, payload.length / 256, payload.length % 256, payload].flatten.pack('C*'), 0
  end
  
  def receive_message
    header = @socket.recv(4)
    message_type, node_address, payload_length = *header.unpack('CCn')
    return @socket.recv(payload_length).unpack('C*')
  end
  
  def connect
    begin
      # connect to the terminal
      @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      @socket.connect(@sockaddr)
      
      # wait for the card to be inserted
      send_message [0, 1, 0, 0], 0
      receive_message # ATR should come here, but who cares
    rescue
      @socket = nil
      return false
    end
    return true
  end
  
  def to_s
    "#<JCOP Remote Terminal: disconnected>" if @socket.nil?
    "#<JCOP Remote Terminal: #{@remote_host}:#{@remote_port}>"    
  end
  
  def disconnect
    unless @socket.nil?
      @socket.close
      @socket = nil
    end
  end
  
  def issue_apdu(apdu)
    send_message apdu
    return receive_message
  end
end
