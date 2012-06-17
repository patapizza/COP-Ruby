#!/usr/bin/env ruby

$: << ".."

require "cop/context_manager"
require "cop/context_adaptation"

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
    raise Exception, "proceed should only be called from adapted methods" if ca.nil?
    adaptations = self.default.manager.adaptations.select do |adaptation|
      adaptation.adapts_class? ca.adapted_class, ca.adapted_selector
    end
    raise Exception, "no adaptation found" if adaptations.empty?
    meth = @@default.manager.adaptation_chain(ca.adapted_class, ca.adapted_selector)[1].adapted_implementation
    if meth.is_a? Proc
      meth.call(meth.parameters)
    else
      meth.bind(ca.adapted_class.class_eval("self.new")).call(meth.parameters)
    end
  end

  def activation_age
    self.manager.context_activation_age(self)
  end

  def activate
    self.manager.signal_activation_request(self)
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
    if action == :overwrite
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
