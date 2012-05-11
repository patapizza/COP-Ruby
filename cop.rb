#!/usr/bin/env ruby

class Context

  @@default = nil
  @@stack = Array.new

  class << self
    attr_writer :stack
  end

  attr_writer :manager
  attr_accessor :adaptations

  def initialize
    @count = 0
    @adaptations = Array.new
  end

  def self.default(*args)
    return @@default = args.first unless args.size == 0
    if @@default.nil?
      @@default = self.new
      @@default.activate
    end
    @@default
  end

  def self.stack
    @@stack
  end

  def self.named(name)
    c = self.new
    c.name= name
    c
  end

  def self.proceed
    ca = @@stack.last
    raise Exception, "proceed should only be called from adaptated methods" if ca.nil?
    index = self.default.adaptations.index do |adaptation|
      adaptation.adapts_class? ca.adapted_class, ca.adapted_selector
    end
    raise Exception, "no adaptation found" if index.nil?
    meth = @@default.adaptations[index].adapted_implementation
    if meth.parameters.size == 0
      ca.adapted_class.instance_eval("meth.bind(self.new).call")
    else
      ca.adapted_class.instance_eval("meth.bind(self.new).call(meth.parameters)")
    end
  end

  def activate
    self.activate_adaptations if @count == 0
    @count += 1
    self
  end

  def deactivate
    self.deactivate_adaptations if @count == 1
    @count -= 1 unless @count == 0
    self
  end

  def active?
    @count > 0
  end

  def name
    self.manager.directory[self]
  end

  def name=(new_name)
    new_name.nil? ? self.manager.directory.delete(self) : self.manager.directory[self] = new_name
  end

  def manager
    return @manager unless @manager.nil?
    return @manager = Context.default.manager unless self == Context.default
    @manager = ContextManager.new
    self.name= "default"
    @manager
  end

  def discard
    self.manager.discard_context(self)
    Context.default(nil) if self == Context.default
    @adaptations.each do |adaptation|
      self.remove_existing_adaptation(adaptation)
    end
  end

  def to_s
    (self.name.nil? ? "anonymous" : "#{self.name}") + " context"
  end

  def adapt_class(a_class, a_selector, a_method)
    begin
      method = a_class.instance_method(a_selector)
      rescue NameError
        raise Exception, "can't adapt inexistent method #{a_selector.to_s} in #{a_method.to_s}"
    end
    default = ContextAdaptation.in_context(Context.default, a_class, a_selector, method)
    Context.default.add_adaptation(default) { :preserve }
    adaptation = ContextAdaptation.in_context(self, a_class, a_selector, a_method)
    self.add_adaptation(adaptation) { raise Exception, "an adaptation already exists for #{self.to_s}" }
  end

  def add_adaptation(context_adaptation, &block)
    existing = @adaptations.index do |adaptation|
      adaptation.same_target? context_adaptation
    end
    if existing.nil?
      self.add_inexistent_adaptation(context_adaptation)
      return self
    end
    existing = @adaptations[existing]
    action = yield
    if action == :overwritee
      self.remove_existing_adaptation(existing)
      self.add_inexistent_adaptation(context_adaptation)
    else
      raise Exception, "unknown overriding action #{action.to_s}" unless action == :preserve
    end
  end

  def add_inexistent_adaptation(context_adaptation)
    raise Exception, "can't add foreign adaptation" unless self == context_adaptation.context
    @adaptations.push(context_adaptation)
    self.manager.activate_adaptation(context_adaptation) if self.active?
  end

  def remove_existing_adaptation(context_adaptation)
    raise Exception, "can't remove foreign adaptation" unless self == context_adaptation.context
    self.manager.deactivate_adaptation(context_adaptation) if self.active?
    raise Exception, "can't remove adaptation" if @adaptations.delete(context_adaptation).nil?
    @@stack.pop
  end

  def activate_adaptations
    @adaptations.each do |adaptation|
      begin
        self.manager.activate_adaptation(adaptation)
	rescue Exception
	  self.rollback_adaptations
	  raise Exception, $!
      end
    end
  end

  def deactivate_adaptations
    @adaptations.each do |adaptation|
      self.manager.deactivate_adaptation(adaptation)
    end
  end

  def rollback_adaptations
    deployed = self.manager.adaptations.select do |adaptation|
      adaptation.context == self
    end
    deployed.each do |adaptation|
      self.manager.deactivate_adaptation(adaptation)
    end
  end

end

class ContextManager
  
  @@default = nil

  attr_accessor :directory, :adaptations

  def initialize
    @directory = Hash.new
    @adaptations = Array.new
  end

  def discard_context(context)
    raise Exception "can't discard outside context manager" if context.manager != self
    raise Exception, "can't discard an active context" if context.active?
    @directory.delete(self)
  end

  def activate_adaptation(context_adaptation)
    index = @adaptations.index do |adaptation|
      adaptation.context != Context.default and adaptation.same_target? context_adaptation
    end
    raise Exception, "conflicting adaptation for #{context_adaptation.adapted_class.to_s}.#{context_adaptation.adapted_selector.to_s}" unless index.nil?
    @adaptations.push(context_adaptation)
    context_adaptation.deploy
  end

  def deactivate_adaptation(context_adaptation)
    raise Exception, "can't deactivate unmanaged adaptation" if @adaptations.delete(context_adaptation).nil?
    default = Context.default.adaptations.index do |adaptation|
      adaptation.adapts_class? context_adaptation.adapted_class, context_adaptation.adapted_selector
    end
    raise Exception, "can't find default behavior for removed adaptation" if default.nil?
    Context.default.adaptations[default].deploy
  end

end

class ContextAdaptation

  attr_accessor :context, :adapted_class, :adapted_selector, :adapted_implementation

  def self.in_context(a_context, a_class, a_selector, a_method)
    ca = self.new
    ca.context= a_context
    ca.adapted_class= a_class
    ca.adapted_selector= a_selector
    ca.adapted_implementation= a_method
    ca
  end

  def deploy
    x = @adapted_implementation
    y = self
    if @context != Context.default
       @adapted_class.send(:define_method, @adapted_selector, lambda { |args = x.parameters, ca = y| Context.stack= Context.stack.push(ca); r = x.call(args); Context.stack.pop(); r })
    else
      @adapted_class.send(:define_method, @adapted_selector, @adapted_implementation)
    end
  end

  def adapts_class?(a_class, a_symbol)
    self.adapted_class == a_class and self.adapted_selector == a_symbol
  end

  def same_target?(other)
    self.adapts_class? other.adapted_class, other.adapted_selector
  end

  def to_s
    "for #{@adapted_selector.to_s} of #{@adapted_class.to_s} using #{@adapted_implementation.nil? ? "no implementation" : @adapted_implementation.name.to_s} in #{@context.to_s}"
  end

end
