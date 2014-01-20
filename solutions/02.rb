class TodoList
  include Enumerable

  attr_reader :tasks

  def self.parse(text)
    tasks = text.each_line.map do |line|
      Task.parse_line line
    end
    TodoList.new tasks
  end

  def initialize tasks
    @tasks = tasks
  end

  def each(&block)
    @tasks.each &block
  end

  def filter criteria
    TodoList.new @tasks.select { |task| criteria.matches? task }
  end

  def adjoin(other)
    TodoList.new @tasks | other.tasks
  end

  def tasks_todo
    filter(Criteria.status :todo).tasks.length
  end

  def tasks_in_progress
    filter(Criteria.status :current).tasks.length
  end

  def tasks_completed
    filter(Criteria.status :done).tasks.length
  end

  def completed?
    tasks_completed == @tasks.length
  end
end

class Task
  def self.parse_line line
    attrs = line.split('|').map do |attr|
      attr.strip
    end
    Task.new *attrs
  end

  attr_reader :status, :description, :priority, :tags

  def initialize status, description, priority, tags
    @status = status.downcase.to_sym
    @description = description
    @priority = priority.downcase.to_sym
    @tags = tags.split ', '
  end
end

class Criteria
  class << self
    def status status
      Criteria.new { |task| task.status == status }
    end

    def tags tags
      Criteria.new do |task|
        (tags - task.tags).empty?
      end
    end

    def priority priority
      Criteria.new { |task| task.priority == priority }
    end
  end

  def initialize &block
    @criterion = block
  end

  def matches?(task)
    @criterion.call(task)
  end

  def &(other)
    Criteria.new { |task| self.matches?(task) and other.matches?(task) }
  end

  def |(other)
    Criteria.new { |task| self.matches?(task) or other.matches?(task) }
  end

  def !
    Criteria.new { |task| not matches?(task) }
  end
end

