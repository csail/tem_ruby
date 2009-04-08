require 'socket'

# :nodoc: namespace
module Tem::Transport
  
# Implements the transport layer for a JCOP simulator instance.
class JcopRemoteTransport
  include JavaCardMixin
  include JcopRemoteProtocol
  
  # Creates a new unconnected transport for a JCOP simulator serving TCP/IP.
  #
  # The options parameter must have the following keys:
  #   host:: the DNS name or IP of the host running the JCOP simulator
  #   port:: the TCP/IP port of the JCOP simulator server
  def initialize(options)
    @host, @port = options[:host], options[:port]
    @socket = nil
  end
  
  # 
  def exchange_apdu(apdu)
    send_message @socket, :type => 1, :node => 0, :data => apdu
    recv_message(@socket)[:data]
  end  

  # Makes a transport-level connection to the TEM.
  def connect
    begin
      Socket.getaddrinfo(@host, @port, Socket::AF_INET,
                         Socket::SOCK_STREAM).each do |addr_info|
        begin
          @socket = Socket.new(addr_info[4], addr_info[5], addr_info[6])
          @socket.connect Socket.pack_sockaddr_in(addr_info[1], addr_info[3])
          break
        rescue
          @socket = nil
        end
      end  
      raise 'Connection refused' unless @socket
      
      # Wait for the card to be inserted.
      send_message @socket, :type => 0, :node => 0, :data => [0, 1, 0, 0]
      recv_message @socket  # ATR should come here, but who cares      
    rescue Exception
      @socket = nil
      raise
    end
  end

  # Breaks down the transport-level connection to the TEM.
  def disconnect
    if @socket
      @socket.close
      @socket = nil
    end
  end
  
  def to_s
    "#<JCOP Remote Terminal: disconnected>" if @socket.nil?
    "#<JCOP Remote Terminal: #{@host}:#{@port}>"
  end  
end  # class JcopRemoteTransport 

end  # module Tem::Transport
