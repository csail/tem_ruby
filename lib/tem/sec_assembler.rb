class Tem::SecAssembler
  include Tem::Isa
    
  def initialize(tem_klass)
    @tem_klass = tem_klass
    @body = []
    @labels = {}
    @lines = {}
    @sp, @ep, @extra_bytes = nil, nil, nil
  end
  
  def assemble(&sec_block)
    # call the block to build the SECpack
    yield self
    
    # link in label addresses
    @body.each_with_index do |link_directive, i|
      next unless link_directive.kind_of? Hash
      if label = link_directive[:label]
        raise "label #{label} undefined" unless addr = @labels[label]
      else
        addr = link_directive[:address]
      end

      if link_directive[:relative]
        q = Tem::Abi.send :"signed_to_#{link_directive[:type]}",
                          addr - i - link_directive[:relative]
      else
        q = Tem::Abi.send "to_#{link_directive[:type]}".to_sym, addr
      end
      @body[i, q.length] = *q
    end
            
    Tem::SecPack.new :tem_class => @tem_klass, :body => @body,
                     :labels => @labels, :ep => @ep || 0,
                     :sp => @sp || @body.length,
                     :extra_bytes => @extra_bytes || 0, :lines => @lines
  end
  
  def label(name)
    raise "label #{name} already defined" if @labels[name.to_sym]
    @labels[name.to_sym] = @body.length
  end
  def filler(type_name, count = 1)
    bytes = count * Tem::Abi.send("#{type_name}_length".to_sym)
    @body += Array.new(bytes, 0)
  end
  def immed(type_name, values)
    values = [values] unless values.instance_of? Array
    @body += values.map { |v| Tem::Abi.send :"to_#{type_name}", v }.flatten
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
