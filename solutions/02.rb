class TodoList
  include Enumerable
  require './criteria.rb'

  attr_accessor :tasks

  def initialize(tasks)
    @tasks = tasks
  end

  def each(&block)
    @tasks.each(&block)
  end

  def self.parse(text)
    tasks = text.each_line.map do |line|
      @status, @descr, @priority, *@tags = line.split(/['|'',']/).map(&:strip)
      Task.new @status, @descr, @priority, @tags
    end

    new tasks
  end

  def filter(criteria)
    TodoList.new @tasks.select { |task| criteria.evaluate_for task }
  end

  def adjoin(other)
    TodoList.new (tasks + other.tasks).uniq
  end

  def tasks_todo
    @tasks.count { |task| task.status == :todo }
  end

  def tasks_in_progress
    @tasks.count { |task| task.status == :current }
  end

  def tasks_completed
    @tasks.count { |task| task.status == :done }
  end

  def completed?
    @tasks.all? { |task| task.status == :done }
  end

end

class Task

  attr_reader :status, :description, :priority, :tags

  def status
    @status.downcase.to_sym
  end

  def priority
    @priority.downcase.to_sym
  end

  def initialize(status, description, priority, tags)
    @status = status
    @description = description
    @priority = priority
    @tags = tags
  end

end

class Criteria

  require "Set"

  def initialize(filter)
    @filter = filter
  end

  def evaluate_for(object)
    @filter.call(object)
  end

  def self.status(value)
    Criteria.new ->(x) { x.send(:status) == value }
  end

  def self.priority(value)
    Criteria.new ->(x) { x.send(:priority) == value }
  end

  def self.tags(value)
    Criteria.new ->(x) { Set.new(value).subset? Set.new x.send(:tags) }
  end

  def &(other)
    Criteria.new ->(x){ self.evaluate_for(x) and other.evaluate_for(x) }
  end

  def |(other)
    Criteria.new ->(x){ self.evaluate_for(x) or other.evaluate_for(x) }
  end

  def !
    Criteria.new ->(x){ not self.evaluate_for(x) }
  end

end