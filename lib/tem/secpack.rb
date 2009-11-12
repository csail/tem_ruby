require 'yaml'

class Tem::SecPack
  @@serialized_ivars = [:body, :labels, :ep, :sp, :extra_bytes, :signed_bytes,
                        :encrypted_bytes, :bound, :lines]    
 
  def self.new_from_array(array)
    arg_hash = { }
    @@serialized_ivars.each_with_index { |name, i| arg_hash[name] = array[i] }
    self.new arg_hash
  end
  
  def self.new_from_yaml_str(yaml_str)
    array = YAML.load yaml_str
    new_from_array array
  end

  def to_array
    @@serialized_ivars.map { |m| self.instance_variable_get :"@#{m}" }
  end
  
  def to_yaml_str
    self.to_array.to_yaml.to_s
  end
  
  attr_reader :body, :bound
  attr_reader :lines
  
  def trim_extra_bytes
    @extra_bytes = 0
    while @extra_bytes < @body.length
      break if @body[-@extra_bytes - 1] != 0
      @extra_bytes += 1
    end
    @body.slice! @body.length - @extra_bytes, @extra_bytes    
  end
  
  def expand_extra_bytes
    @body += [0] * @extra_bytes
    @extra_bytes = 0
  end
  
  def initialize(args)
    @@serialized_ivars.map { |m| self.instance_variable_set :"@#{m}", args[m] }
    @bound ||= false
    
    @extra_bytes ||= 0
    # trim_extra_bytes if @extra_bytes == 0
  end
  
  def label_address(label_name)
    @labels[label_name.to_sym]
  end
    
  def bind(public_key, encrypt_from = 0, plaintext_from = 0)
    expand_extra_bytes
    encrypt_from = @labels[encrypt_from.to_sym] unless encrypt_from.kind_of? Numeric
    plaintext_from = @labels[plaintext_from.to_sym] unless plaintext_from.kind_of? Numeric
    
    @signed_bytes = encrypt_from
    @encrypted_bytes = plaintext_from - encrypt_from
    
    secpack_sig = Tem::Abi.tem_hash [tem_header, @body[0...plaintext_from]].flatten
    crypt = public_key.encrypt [@body[encrypt_from...plaintext_from], secpack_sig].flatten
    @body = [@body[0...encrypt_from], crypt, @body[plaintext_from..-1]].flatten
      
    label_delta = crypt.length - @encrypted_bytes         
    @labels = Hash[*(@labels.map { |k, v|
      if v < encrypt_from
        [k, v] 
      elsif v < plaintext_from
        []
      else
        [k, v + label_delta]
      end
    }.flatten)]
    
    #trim_extra_bytes
    @bound = true
  end
  
  def tem_header
    # TODO: use 0x0100 (no tracing) depending on options
    hh = [0x0101, @signed_bytes || 0, @encrypted_bytes || 0, @extra_bytes, @sp,
          @ep].map { |n| Tem::Abi.to_tem_ushort n }.flatten
    hh += Array.new((Tem::Abi.tem_hash [0]).length - hh.length, 0)
    return hh
  end
  private :tem_header
  
  def tem_formatted_body
    # HACK: Ideally, we would allocate a bigger buffer, and then only fill part
    #       of it. Realistically, we'll just send in extra_bytes 0s.
    [tem_header, @body, [0] * @extra_bytes].flatten
  end
  
  def line_info_for_addr(addr)
    return nil unless @lines

    @lines.reverse_each do |info|
      # If something breaks, it's likely to happen after the opcode of the 
      # offending instruction has been read, so assume offending_ip < ip.
      return info if addr >= info[0]
    end
    return @lines.first
  end
  
  def label_info_for_addr(addr)
    @labels.to_a.reverse_each do |info|
      return info.reverse if addr >= info[1]
    end
    return [0, :__start]
  end
  
  # Methods for interacting with the plaintext content of a SECpack.
 
  def get_bytes(label, byte_count)
    expand_extra_bytes
    raise "Unknown label #{label}" unless addr = @labels[label]
    bytes = @body[addr, byte_count]
    #trim_extra_bytes
    bytes
  end
  
  def set_bytes(label, bytes)
    expand_extra_bytes
    raise "Unknown label #{label}" unless addr = @labels[label]
    @body[addr, bytes.length] = bytes
    #trim_extra_bytes
  end
  
  def set_value(label, abi_type, value)
    set_bytes label, Tem::Abi.send(:"to_#{abi_type}", value)
  end
  
  def get_value(label, abi_type)
    expand_extra_bytes
    raise "Unknown label #{label}" unless addr = @labels[label]
    value = Tem::Abi.send :"read_#{abi_type}", @body, addr
    #trim_extra_bytes
    value
  end
end
