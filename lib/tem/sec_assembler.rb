class Tem::SecAssembler
  def initialize(tem_klass)
    @tem_klass = tem_klass
    @body = []
    @labels = {}
    @lines = {}
    @sp, @ep, @extra_bytes = nil, nil, nil
  end
    
  def self.opcode(name, value, *params)
    p_hash = {}
    params.each_index { |i| p_hash[params[i][:name]] = i unless params[i][:name].nil? }
    
    define_method(name.to_sym) do |*m_params|
      # linearize the parameters
      param_idx = 0
      s_params = []
      m_params.each_index do |i|
        if m_params[i].instance_of? Hash
          raise "no embedded hashes please! (check parameter #{param_idx})" unless i == m_params.length - 1         
          m_params[i].each do |k, v|
            raise "no parameter with name #{k} for opcode #{name}" if p_hash[k].nil?
            raise "parameter #{k} was already assigned a value" unless (param_idx <= p_hash[k] and s_params[p_hash[k]].nil?)
            s_params[p_hash[k]] = v
          end        
        else
          s_params[param_idx] = m_params[i]
          param_idx += 1
        end
      end
      
      # check for missing parameters
      raise "opcode #{name} requires more parameters" unless s_params.length == params.length and s_params.all? { |v| !v.nil? }
      
      # encode parameters
      @lines[@body.length] = Kernel.caller(0)
      @body += @tem_klass.to_tem_ubyte(value)
      s_params.each_index do |i|
        if (s_params[i].kind_of? Numeric) && !params[i][:relative]
          @body += @tem_klass.send "to_tem_#{params[i][:type]}".to_sym, s_params[i]
        else
          @body << { :type => params[i][:type], :relative => params[i][:reladdr] ? params[i][:reladdr] : false }.merge!(
            (s_params[i].kind_of? Numeric) ? { :address => s_params[i].to_i } : { :label => s_params[i].to_sym })
          @body += (@tem_klass.send "to_tem_#{params[i][:type]}".to_sym, 0)[1..-1]
        end
      end        
    end
  end
  
  def assemble(&sec_block)
    # call the block to build the SECpack
    yield self
    
    # link in label addresses
    @body.each_index do |i|
      if @body[i].kind_of? Hash
        raise "label #{@body[i][:label]} undefined" if (!@body[i][:label].nil? and @labels[@body[i][:label]].nil?)
        addr = @body[i][:label].nil? ? @body[i][:address] : @labels[@body[i][:label]]
        q = @body[i][:relative] ? (@tem_klass.send "to_tem_#{@body[i][:type]}_reladdr".to_sym, addr - i - @body[i][:relative]) :
                                (@tem_klass.send "to_tem_#{@body[i][:type]}".to_sym, addr) 
        @body[i, q.length] = *q
      end
    end
            
    return Tem::SecPack.new(:tem_class => @tem_klass, :body => @body, :labels => @labels,
      :ep => @ep || 0, :sp => @sp || @body.length, :extra_bytes => @extra_bytes || 0, :lines => @lines)
  end
  
  def label(name)
    raise "label #{name} already defined" unless @labels[name.to_sym].nil?
    @labels[name.to_sym] = @body.length
  end
  def filler(type_name, count = 1)
    bytes = count * @tem_klass.send("tem_#{type_name}_length".to_sym)
    @body += Array.new(bytes, 0)
  end
  def immed(type_name, values)
    values = [values] unless values.instance_of? Array
    @body += values.map { |v| @tem_klass.send "to_tem_#{type_name}".to_sym, v }.flatten
  end    
  def entry
    @ep = @body.length
  end
  def stack
    @sp = @body.length
  end
  def extra(extra_bytes)
    @extra_bytes = extra_bytes
  end
end

