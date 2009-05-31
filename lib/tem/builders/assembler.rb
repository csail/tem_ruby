# :nodoc: namespace
module Tem::Builders  

# Builder class for the code assembler builder.
class Assembler
  # Creates a builder targeting a module / class.
  #
  # The given parameter should be a class or module.
  def self.define_assembler(class_or_module)  # :yields: abi
    yield new(class_or_module)
  end
  
  # Defines the ISA targeted by the assembler.
  #
  # This method should be called early in the assembler definition. It creates
  # the proxy and builder classes for the assembling process. 
  def target_isa(isa_module)    
    @isa = isa_module
    target.const_set :Isa, @isa
    @abi = @isa.const_get :Abi
    target.const_set :Abi, @abi
    
    define_proxy_class
    define_builder_class
    augment_target
  end
  
  # Defines the methods for implementing a stack directive.
  #
  # The following options are supported:
  #   label:: the label serving as the stack marker (required)
  #   slot_type:: the ABI type representing a stack slot
  #
  # The following method is defined in the proxy for a directive named 'name':
  #   * name(slots = 0) -> places a stack marker and allocates stack slots
  def stack_directive(name, options)
    unless @proxy_class
      raise "target_isa must be called before other builder methods"
    end
    # Capture these in the closure.
    stack_label = options[:label]
    slot_length = @abi.send :"#{options[:slot_type]}_length" 
    proxy_defines = Proc.new do
      define_method name.to_sym do |*args|
        case args.length
        when 0
          slots = 0
        when 1
          slots = args.first
        else
          raise "#{name}: given #{args.length} arguments, wanted at most 1"
        end
        @assembler.emit_label stack_label
        if slots > 0
          @assembler.emit_bytes name, :emit => Array.new(slots * slot_length, 0)
        end
      end
    end    
    @proxy_class.class_eval &proxy_defines
    (class << @proxy_class; self; end).module_eval &proxy_defines    
  end
  
  # Defines the methods for implementing a labeling directive.
  #
  # The following method is defined in the proxy for a directive named 'name':
  #   * name(label_name) -> creates a label named label_name at the current byte
  def label_directive(name, options = {})
    unless @proxy_class
      raise "target_isa must be called before other builder methods"
    end
    proxy_defines = Proc.new do
      define_method name.to_sym do |label_name|
        @assembler.emit_label label_name.to_sym
      end
    end    
    @proxy_class.class_eval &proxy_defines
    (class << @proxy_class; self; end).module_eval &proxy_defines    
  end
  
  # Defines the methods for implementing a special label directive.
  #
  # The following method is defined in the proxy for a directive named 'name':
  #   * name -> creates a label named label_name at the current byte
  def special_label_directive(name, label_name)
    unless @proxy_class
      raise "target_isa must be called before other builder methods"
    end
    proxy_defines = Proc.new do
      define_method name.to_sym do
        @assembler.emit_label label_name.to_sym
      end
    end    
    @proxy_class.class_eval &proxy_defines
    (class << @proxy_class; self; end).module_eval &proxy_defines
  end

  # Defines the methods for implementing a zero-inserting directive.
  #
  # The following method is defined in the proxy for a directive named 'name':
  #   * name(abi_type, count = 1) -> creates count zeros of abi_type
  def zeros_directive(name, options = {})
    unless @proxy_class
      raise "target_isa must be called before other builder methods"
    end
    # Capture this in the closure.
    abi = @abi
    proxy_defines = Proc.new do
      define_method name.to_sym do |*args|
        if args.length == 1 || args.length == 2
          type_name, count = args[0], args[1] || 1
        else
          raise "#{name}: given #{args.length} arguments, wanted 1 or 2"
        end
        bytes = count * abi.send(:"#{type_name}_length")
        @assembler.emit_bytes name, :emit => Array.new(bytes, 0)
      end
    end    
    @proxy_class.class_eval &proxy_defines
    (class << @proxy_class; self; end).module_eval &proxy_defines    
  end
    
  # Defines the methods for implementing a data-emitting directive.
  #
  # The following method is defined in the proxy for a directive named 'name':
  #   * name(abi_type, values = 1) -> emits the given values as abi_type
  def data_directive(name, options = {})
    unless @proxy_class
      raise "target_isa must be called before other builder methods"
    end
    # Capture this in the closure.
    abi = @abi
    proxy_defines = Proc.new do
      define_method name.to_sym do |abi_type, values|
        values = [values] unless values.instance_of? Array
        data = []
        values.each { |value| data += abi.send :"to_#{abi_type}", value }
        @assembler.emit_bytes :immed, :emit => data
      end
    end    
    @proxy_class.class_eval &proxy_defines
    (class << @proxy_class; self; end).module_eval &proxy_defines    
  end
  
  # (private) Defines the builder class used during assembly.
  #
  # Builders maintain intermediate results during the assembly process. In a
  # nutshell, a builder collects the bytes, labels and linker directives, and
  # puts them together at the end of the assembly process.
  #
  # Builder classes are synthesized automatically if they don't already exist.
  # To have a builder class inherit from another class, define it before calling
  # target_isa. Builder classes are saved as the Builder constant in the
  # assembler class.
  #
  # Builder classes are injected the code in Assembler::CodeBuilderBase. Look
  # there for override hooks into the assembly process.
  def define_builder_class
    if @target.const_defined? :Builder
      @builder_class = @taget.const_get :Builder
    else
      @builder_class = Class.new
      @target.const_set :Builder, @builder_class
    end
    @builder_class.send :include, Assembler::CodeBuilderBase
  end
  private :define_builder_class
  
  # (private) Defines the proxy class used during assembly.
  #
  # The proxy class is yielded to the block given to the assemble call, which
  # provides the code to be assembled. For clarity, the proxy class is
  # synthesized so it only contains the methods that are useful for assembly.
  #
  # The proxy class is always automatically synthesized, and is available under
  # the constant Proxy in the assembler class.
  def define_proxy_class
    @proxy_class = Class.new Assembler::ProxyBase
    target.const_set :Proxy, @proxy_class
    
    @proxy_class.const_set :Abi, @abi
    @proxy_class.const_set :Isa, @isa
    
    # Capture the ISA and ABI in the closure.
    isa = @isa
    proxy_defines = Proc.new do
      isa.instance_methods.each do |method|
        if method[0, 5] == 'emit_'
          isa_method_msg = method.to_sym
          proxy_method_name = method[5, method.length].to_sym
          define_method proxy_method_name do |*args|
            emit_data = isa.send isa_method_msg, *args
            @assembler.emit_bytes proxy_method_name, emit_data
          end
        end
      end
    end
    @proxy_class.class_eval &proxy_defines
    (class << @proxy_class; self; end).module_eval &proxy_defines    
  end
  private :define_proxy_class
    
  # (private) Augments the target with the assemble method.
  def augment_target
    # Capture this data in the closure.
    proxy_class = @proxy_class
    builder_class = @builder_class
    defines = Proc.new do
      # Assembles code.
      def assemble(&block)
        _assemble block
      end
      
      # Internal method for assembling code.
      #
      # We need to use a block to define this method, so we can capture the
      # outer variables (proxy_class and builder_class) in its closure. However,
      # blocks can't take blocks as parameters (at least not in MRI 1.8). So
      # we use a regular method definition (assemble) which wraps the block
      # into a Proc received by _assemble.
      define_method :_assemble do |block|
        code_builder = builder_class.new
        code_builder.start_assembling
        proxy = proxy_class.new(code_builder)
        block.call proxy
        code_builder.done_assembling proxy
      end
      private :_assemble
    end
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines        
  end
  
  # The module / class impacted by the builder.
  attr_reader :target
  
  # Creates a builder targeting a module / class. 
  def initialize(target)
    @target = target
    @isa, @abi, @proxy = nil, nil, nil    
  end
  private_class_method :new
end  # class Assembler


# Base class for the assemblers' proxy objects.
#
# The proxy object is the object that is yielded out of an assembler's
# assemble class method. 
class Assembler::ProxyBase
  def initialize(assembler)
    @assembler = assembler
  end
end

# Module injected into the assembler's code builder class.
module Assembler::CodeBuilderBase
  # Called by assemble before its associated block receives control.
  #
  # This method is responsible for setting up the state needed by the emit_
  # methods. 
  def start_assembling
    @bytes = []
    @link_directives = []
    @line_info = []
    @labels = {}
  end
  
  # Emits code or data bytes, with associated link directives.
  def emit_bytes(emit_atom_name, emit_data)
    (emit_data[:link_directives] || []).each do |directive|
      directive[:offset] += @bytes.length
      @link_directives << directive
    end
    
    emit_data[:emit] ||= []
    if emit_data[:emit].length > 0
      @line_info << [@bytes.length, emit_atom_name, Kernel.caller(2)]  
    end    
    @bytes += emit_data[:emit] || []    
  end
  
  # Emits labels, which are symbolic names for addresses.
  def emit_label(label_name)
    raise "label #{label_name} already defined" if @labels[label_name]
    @labels[label_name] = @bytes.length
  end
  
  # Called by assemble after its associated block returns.
  #
  # This method is responsible for the final assembly steps (i.e. linking) and
  # returning a processed result. The method's result is returned by assemble. 
  def done_assembling(proxy)
    # Process link directives.
    abi = proxy.class.const_get :Abi
    @link_directives.each do |directive|
      if label = directive[:label]
        raise "Label #{label} undefined" unless address = @labels[label]
      else
        address = directive[:address]
      end
      if directive[:relative]
        address -= directive[:offset] + directive[:relative]
      end
      address_bytes = abi.send :"signed_to_#{directive[:type]}", address
      @bytes[directive[:offset], address_bytes.length] = *address_bytes
    end
    
    # Wrap all the built data into a nice package and return it.
    { :bytes => @bytes, :link_directives => @link_direcives, :labels => @labels,
      :line_info => @line_info }
  end
end

end  # namespace Tem::Builders
