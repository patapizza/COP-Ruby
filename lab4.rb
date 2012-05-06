#!/usr/bin/env ruby

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
    self
  end

  def deactivate
    @count -= 1 unless @count == 0
    self
  end

  def active?
    @count > 0
  end

  def name(*args)
    if args.size == 0
      self.manager.directory[self]
    else
      if args[0].nil?
        self.manager.directory.delete(self)
      else
        self.manager.directory[self] = args[0]
      end
    end
  end

  def manager
    if @manager.nil?
      if self == Context.default
	@manager = ContextManager.new
	self.name("default")
      else
        @manager = Context.default.manager
      end
    end
    @manager
  end

  def discard
    @manager.discard_context(self)
    Context.default(nil) if self == Context.default
  end

  def to_s
    s = self.name.nil? ? "anonymous" : "#{ self.name }"
    s + " context"
  end

end

class ContextManager
  
  @@default = nil

  attr_accessor :directory

  def initialize
    @directory = Hash.new
  end

  def discard_context(context)
    raise Exception if context.manager != self
    raise Exception if context.active?
    @directory.delete(self)
  end

end
