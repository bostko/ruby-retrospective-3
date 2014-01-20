module Asm
  def self.asm(&block)
    interpreter = Interpreter.new
    interpreter.instance_eval &block
    interpreter.exec
    interpreter.register_values
  end

  module Registers
    [:ax, :bx, :cx, :dx].each do |register|
      define_method register do
        register
      end
    end
  end

  module Instructions
    instructions = [:mov, :inc, :dec, :cmp, :jmp, :je, :jne, :jl, :jle, :jg, :jge]

    instructions.each do |instruction|
      define_method(instruction) do |first_arg, second_arg = nil|
        if second_arg
          send("_#{instruction}".to_sym, first_arg, second_arg)
        else
          send("_#{instruction}".to_sym, first_arg)
        end
      end
    end

    instance_methods.each do |method_name|
      method = instance_method(method_name)
      define_method(method_name) do |*args|
        unless method_name == :label
          fifo << ["_#{method_name}".to_sym, method, args]
        end
      end
    end

    def label(label)
      current_instruction = fifo.length
      self.class.send(:define_method, label) do
        current_instruction
      end
    end

    def method_missing(method_name, *arguments)
      method_name
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end
  end

  module InstructionsImplementation
    def _mov(register, source)
      set_register register, evaluate(source)
    end

    def _inc(register, value = 1)
      value = value.nil? ? 1 : value
      set_register register, evaluate(register) + evaluate(value)
    end

    def _dec(register, value = 1)
      value = value.nil? ? 1 : value
      set_register register, evaluate(register) - evaluate(value)
    end

    def _cmp(register, value)
      self.cmp_temp = evaluate(register) <=> evaluate(value)
    end
  end

  module JumpInstructionsImplementation
    def _je(where)
      if cmp_temp == 0
        _jmp(where)
      end
    end

    def _jne(where)
      if cmp_temp != 0
        _jmp(where)
      end
    end

    def _jl(where)
      if cmp_temp < 0
        _jmp(where)
      end
    end

    def _jle(where)
      if cmp_temp <= 0
        _jmp(where)
      end
    end

    def _jg(where)
      if cmp_temp > 0
        _jmp(where)
      end
    end

    def _jge(where)
      if cmp_temp >= 0
        _jmp(where)
      end
    end

    def _jmp(where)
      found = false
      fifo.each_with_index do |method_call, index|
        n = where.kind_of?(Symbol) ? send(where) : where
        if found or n == index
          jump_passed = method_call[1].bind(self).(*method_call[2])

          if jump_instruction?(method_call[0]) and jump_passed
            break
          end
          found = true
        end
      end
      true
    end

    def jump_instruction?(instruction)
      [:_je, :_jmp, :_jne, :_jl, :_jle, :_jg, :_jge].include?(instruction)
    end
  end

  class Interpreter
    include Registers
    include Instructions
    include InstructionsImplementation
    include JumpInstructionsImplementation

    attr_accessor :cmp_temp
    attr_reader :fifo

    def initialize
      @registers = Hash.new(0)
      @fifo = []
    end

    def exec
      jump_called = false
      fifo.each do |method_call|
        jump_passed = method_call[1].bind(self).(*method_call[2])
        if jump_instruction?(method_call[0]) && jump_passed
          break
        end
      end
    end

    def set_register(register, value)
      @registers[register] = value
    end

    def register_value(register)
      @registers[register]
    end

    def evaluate(source)
      source.kind_of?(Symbol) ? register_value(source) : source
    end

    def register_values
      [:ax, :bx, :cx, :dx].map { |register| @registers[register] }
    end
  end
end

