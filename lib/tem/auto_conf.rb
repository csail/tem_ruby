module Tem
  # Automatically configures a TEM.
  #
  # In case of success, the $tem global variable is set to a Tem::Session that
  # can be used to talk to some TEM. An exception will be raised if the session
  # creation fails.
  #
  # It is safe to call auto_conf multiple times. A single session will be open.
  def self.auto_conf
    return @tem if defined?(@tem) and @tem
    
    @tem = auto_tem
    $tem = @tem
    class << @tem
      def disconnect
        Tem.instance_variable_set :@tem, nil
        $tem = nil
        super
      end
    end
  end

  # Creates a new session to a TEM, using an automatically-configured transport.
  # :call-seq:
  #   Tem.auto_tem -> Tem::Session
  #
  # In case of success, returns a Tem::Session that can be used to talk to some
  # TEM. An exception will be raised if the session creation fails. 
  def self.auto_tem
    transport = Smartcard::Iso.auto_transport
    raise 'No suitable ISO7816 smart-card was found' unless transport
    Tem::Session.new transport
  end
end
