class Tem::Assembler
  Tem::Builders::Assembler.define_assembler self do |assembler|
    assembler.target_isa Tem::Isa
    assembler.stack_directive :stack, :label => :__stack,
                                      :slot_type => :tem_short
    assembler.label_directive :label
    assembler.special_label_directive :entry, :__entry
    assembler.zeros_directive :zeros
    assembler.data_directive :data
  end
  
  class Builder
    def done_assembling(proxy)
      assembled = super
      bytes = assembled[:bytes]
      labels = assembled[:labels]
      Tem::SecPack.new :body => bytes,
                       :labels => labels, :ep => labels[:__entry] || 0,
                       :sp => labels[:__stack] || bytes.length,
                       :lines => assembled[:line_info]    
    end
  end
end
