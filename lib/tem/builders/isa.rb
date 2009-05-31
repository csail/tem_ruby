require 'openssl'


# :nodoc: namespace
module Tem::Builders  

# Builder class for the ISA (Instruction Set Architecture) builder.
class Isa
  # Creates a builder targeting a module / class.
  #
  # class_or_module will receive the ISA method definitions. abi should be a
  # class or module containing the ABI definitions that the ISA definitions
  # refer to.
  #
  # The following options are supported:
  #   opcode_type:: the ABI type encoding the instructions' opcodes (required)
  def self.define_isa(class_or_module, abi, options)  # :yields: isa
    yield new(class_or_module, abi, options[:opcode_type])
  end
  
  # Defines the methods for handling an instruction in the IA.
  # 
  # The instruction's arguments are provided as an array of hashes. Each hash
  # describes one argument, and the ordering in the array reflects the encoding
  # order. The following hash keys are supported: 
  #   name:: if defined, the argument can be provided as a named argument;
  #          named arguments must follow positional arguments
  #   type:: the ABI type encoding the argument (required)
  #   reladdr:: if defined, the encoded argument value is relative to the
  #             address of the instruction containing the argument;
  #
  # The result of encoding an instruction is a Hash with the following keys:
  #   emit:: the bytes to be emitted into the code stream 
  #   link_directives:: an array of directives for the code linker
  #
  # Each linker directive refers to an address cell (location in the code
  # representing an address that the linker must adjust. The following keys can
  # be present:
  #   type:: the ABI type for the address cell (required)
  #   offset:: the address cell's offset in the emitted bytes (required)
  #   address:: the absolute address to point to (mutually exclusive with label)
  #   label:: the name of a label that the address must point to
  #   relative:: if false, the address cell holds an absolute address;
  #              otherwise, the cell's value is computed as follows:
  #              target address - cell address + value of relative;
  #              (optional, default value is false)
  # The following methods are defined for a type named 'name':
  #   * encode_name(*arguments) -> Hash
  def instruction(opcode, name, *iargs)
    encoded_opcode = @abi.send :"to_#{@opcode_type}", opcode
    abi = @abi  # Capture the ABI in the method closures.
    named_indexes = {}
    iargs.map { |iarg| iarg[:name] }.
          each_with_index { |argname, i| named_indexes[argname] = i if argname }
    arg_encode_msgs = iargs.map { |iarg| :"to_#{iarg[:type]}" }
    defines = Proc.new do 
      define_method :"emit_#{name}" do |*args|
        # Flatten arguments by resolving named parameters to indexes.
        arg_index = 0
        fargs = []
        args.each_with_index do |arg, i|
          fargs[i] = arg and next unless arg.kind_of? Hash
          
          if i != args.length - 1
            raise "Named arguments must follow inline arguments! (arg #{i})"
          end
          arg.each do |k, v|
            raise "#{name} has no #{k} argument" unless i = named_indexes[k]
            raise "Argument #{k} was already assigned a value" if fargs[i]
            fargs[i] = v
          end
        end
          
        arg_count = fargs.inject(0) { |acc, v| v.nil? ? acc : acc + 1 }
        if arg_count != iargs.length
          raise "#{name} requires #{fargs.length} args, given #{arg_count}"
        end
        
        # Encode parameters.
        # @lines[@body.length] = Kernel.caller(0)
        
        emit = encoded_opcode
        link_directives = []
        fargs.each_with_index do |arg, i|
          if (arg.kind_of? Numeric) && !arg[:reladdr]
            emit += abi.send arg_encode_msgs[i], arg
          else
            link_directive = { :type => iargs[i][:type], :offset => emit.length,
                               :relative => iargs[i][:reladdr] || false }
            if arg.kind_of? Numeric
              link_directive[:address] = arg.to_i
            else
              link_directive[:label] = arg.to_sym
            end
            link_directives << link_directive
            emit += abi.send arg_encode_msgs[i], 0
          end
        end
        { :emit => emit, :link_directives => link_directives }
      end
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines
  end  
  
  # The module / class impacted by the builder.
  attr_reader :target
  
  # Creates a builder targeting a module / class. 
  def initialize(target, abi, opcode_type)
    @target = target
    @target.const_set :Abi, abi
    @abi = abi
    @opcode_type = opcode_type
  end
  private_class_method :new  
end  # class Isa

end  # namespace Tem::Builders
