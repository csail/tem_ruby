require 'yaml'

class Tem::SecPack
  @@serialized_members = [:body, :labels, :ep, :sp, :extra_bytes, :signed_bytes, :encrypted_bytes, :bound, :lines]
  
  def self.new_from_array(array)
    arg_hash = { :tem_class => Tem::Session }
    @@serialized_members.each_index { |i| arg_hash[@@serialized_members[i]] = array[i] }
    self.new(arg_hash)
  end
  
  def self.new_from_yaml_str(yaml_str)
    array = YAML.load yaml_str
    new_from_array array
  end

  def to_array
    @@serialized_members.map { |m| self.instance_variable_get('@' + m.to_s) }
  end
  
  def to_yaml_str
    self.to_array.to_yaml.to_s
  end
  
  attr_reader :body, :bound
  attr_reader :lines
  
  def initialize(args)
    @tem_klass = args[:tem_class]
    @@serialized_members.map { |m| self.instance_variable_set('@' + m.to_s, args[m]) }
    @bound ||= false
  end
  
  def label_address(label_name)
    @labels[label_name.to_sym]
  end
  
  def tem_header
    # TODO: use 0x0100 (no tracing) depending on options
    hh = [0x0101, @signed_bytes, @encrypted_bytes, @extra_bytes, @sp, @ep].map { |n| @tem_klass.to_tem_ushort n }.flatten
    hh += Array.new((@tem_klass.hash_for_tem [0]).length - hh.length, 0)
    return hh
  end
  
  def bind(public_key, encrypt_from = 0, plaintext_from = 0)
    encrypt_from = @labels[encrypt_from.to_sym] unless encrypt_from.instance_of? Numeric
    plaintext_from = @labels[plaintext_from.to_sym] unless plaintext_from.instance_of? Numeric
    
    @signed_bytes = encrypt_from
    @encrypted_bytes = plaintext_from - encrypt_from
    
    proc_sig = @tem_klass.hash_for_tem [tem_header, @body[0...plaintext_from]].flatten
    crypt = public_key.encrypt [@body[encrypt_from...plaintext_from], proc_sig].flatten
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
    
    @bound = true
  end
  
  def tem_formatted_body()
    return [tem_header, @body].flatten 
  end
  
  def stack_for_ip(ip)
    return nil unless @lines

    max_value = -1
    st = nil
    @lines.each do |st_ip, stack|
      # if something breaks, it's likely to happen after the opcode
      # of the offending instruction has been read, so assume offending_ip < ip
      max_value, st = st_ip, stack if st_ip < ip && max_value < st_ip
    end
    return st
  end
end
