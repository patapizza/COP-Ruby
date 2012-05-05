#!/usr/local/bin/ruby

class Context

  @@default = nil

  attr_writer :manager

  def initialize
    @count = 0
  end

  def self.default(*args)
    if args.size == 0
      if @@default.nil?
        @@default = self.new
	@@default.activate
      end
      @@default
    else
      @@default = args[0]
    end
  end

  def self.named(name)
    c = self.new
    c.name(name)
    c
  end

  def activate
    @count += 1
  end

  def deactivate
    @count -= 1 unless @count == 0
  end

  def active?
    @count > 0
  end

  def name(*args)
    if args.size == 0
      self.manager.directory[self]
    else
      self.manager.directory[self] = args[0]
    end
  end

  def manager
    if @manager.nil?
      if self == self.class.default
	@manager = ContextManager.new
	@name = "default"
      else
        @manager = self.class.default.manager
      end
    end
    @manager
  end

end

class ContextManager
  
  @@default = nil

  attr_accessor :directory

  def initialize
    @directory = Hash.new
  end

end

c = Context.named("test")
puts c.name
d = Context.default
puts Context.default.name
puts d.name
