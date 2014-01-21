module Asm

  module CommonInstructions
    def move(destination_register, source)
      @registers[destination_register] = get_value(source)
    end

    def increment(destination_register, value = 1)
      @registers[destination_register] += get_value(value)
    end

    def decrement(destination_register, value = 1)
      @registers[destination_register] -= get_value(value)
    end

    def compare(destination_register, value)
      @flag = @registers[destination_register] - get_value(value)
    end

    private

    def get_value(value)
      value = @registers.key?(value) ? @registers[value] : value
    end
  end

  module JumpInstructions
    def jump(filter, where)
      filter.call(@flag) ? where : -1
    end
  end

  module CommonInstructionsInterpreter
    include CommonInstructions

    def mov(*args)
      @instructions << {name: :move, parameters: args}
    end

    def inc(*args)
      @instructions << {name: :increment, parameters: args}
    end

    def dec(*args)
      @instructions << {name: :decrement, parameters: args}
    end

    def cmp(*args)
      @instructions << {name: :compare, parameters: args}
    end

    def label(label_name)
      @labels[label_name] = @instructions.count
    end
  end

  module JumpInstructionsInterpreter
    include JumpInstructions

    @@jump_conditions = {
      jmp: proc { |x| x == x },
      je: proc { |x| x == 0 },
      jne: proc { |x| x != 0 },
      jl: proc { |x| x < 0 },
      jle: proc { |x| x <= 0 },
      jg: proc { |x| x > 0 },
      jge: proc { |x| x >= 0 }
    }

    def jmp(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:jmp], where]}
    end

    def je(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:je], where]}
    end

    def jne(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:jne], where]}
    end

    def jl(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:jl], where]}
    end

    def jle(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:jle], where]}
    end

    def jg(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:jg], where]}
    end

    def jge(where)
      @instructions << {name: :jump, parameters: [@@jump_conditions[:jge], where]}
    end
  end

  class AsmDSLInterpreter
    include CommonInstructionsInterpreter
    include JumpInstructionsInterpreter

    def initialize
      @registers = {ax: 0, bx: 0, cx: 0, dx: 0}
      @instructions = []
      @labels = {}
      @flag = 0
    end

    def interpret
      next_index = 0
      while next_index < @instructions.size do
        next_index = execute_instruction(@instructions[next_index], next_index)
      end
      @registers.values
    end

    def execute_instruction(current_instruction, current_index)
      next_index = current_index + 1
      result = public_send current_instruction[:name], *current_instruction[:parameters]
      if current_instruction[:name] == :jump and result != -1
        next_index = @labels.key?(result) ? @labels[result] : result
      end

      next_index
    end

    def method_missing(method_name, *args, &block)
      method_name
    end
  end

  def self.asm(&block)
    interpreter = AsmDSLInterpreter.new
    interpreter.instance_eval &block
    interpreter.interpret
  end
end