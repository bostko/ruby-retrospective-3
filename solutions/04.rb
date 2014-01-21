module Asm
  class Compiler
    attr_reader :instructions, :labels

    def initialize
      @instructions = []
      @labels = {}
    end

    MUTATORS = [:mov, :inc, :dec, :cmp].freeze
    JUMPERS = {
      jmp: proc { true },
      je:  proc { @last_cmp.zero? },
      jne: proc { not @last_cmp.zero? },
      jl:  proc { @last_cmp < 0 },
      jle: proc { @last_cmp <= 0 },
      jg:  proc { @last_cmp > 0 },
      jge: proc { @last_cmp >= 0 },
    }.freeze

    MUTATORS.each do |mutator_name|
      define_method mutator_name do |*arguments|
        @instructions << [mutator_name, *arguments]
      end
    end

    JUMPERS.each do |jumper_name, condition|
      define_method jumper_name do |position|
        @instructions << [:jmp, condition, position]
      end
    end

    def label(name)
      @labels[name] = @instructions.count
    end

    def method_missing(label_or_register_name)
      label_or_register_name
    end

    def self.compile(&program)
      compiler = new
      compiler.instance_eval &program

      [compiler.instructions, compiler.labels]
    end
  end

  class Executor < Struct.new(:instructions, :labels, :ax, :bx, :cx, :dx)
    def mov(register, value)
      self[register] = actual_value(value)
    end

    def inc(register, value = 1)
      self[register] += actual_value(value)
    end

    def dec(register, value = 1)
      self[register] -= actual_value(value)
    end

    def cmp(comparant_one, comparant_two)
      @last_cmp = actual_value(comparant_one) <=> actual_value(comparant_two)
    end

    def jmp(condition, position)
      @current_instruction = actual_position(position).pred if instance_eval &condition
    end

    def self.execute((instructions, labels))
      new(instructions, labels, 0, 0, 0, 0).instance_eval do
        @current_instruction = -1
        while instructions[@current_instruction.next] do
          @current_instruction += 1
          send *instructions[@current_instruction]
        end

        [ax, bx, cx, dx]
      end
    end

    private

    def actual_value(value)
      value.is_a?(Symbol) ? self[value] : value
    end

    def actual_position(position)
      labels.fetch(position, position)
    end
  end

  def self.asm(&program)
    Executor.execute(Compiler.compile &program)
  end
end

