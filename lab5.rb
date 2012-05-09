#!/usr/local/bin/ruby

require "/home/lasher/prog/github/COP-Ruby/lab4"

class Context5 < Context4

  attr_accessor :adaptations

  def initialize
    super.initialize
    @adaptations = Array.new
  end

  def activate
    self.activate_adaptations if count == 0
    super.activate
  end

  def activate_adaptations
    @adaptations.each do |i|
      begin
        self.manager.activate_adaptation(i)
	rescue Exception
	  self.roll_back_adaptations
	  raise Exception, $!
      end
    end
  end

  def adapt_class(a_class, a_selector, a_method)
    method = a_class.allocate.method(a_selector)
    raise Exception, "Cannot adapt inexistent method #{a_selector.to_s} in #{a_method.to_s}" if method.nil?
    default_adaptation = ContextAdaptation.in_context(Context.default, a_class, a_selector, a_method)
    Context.default.add_adaptation(default_adaptation) { :preserve }
    context_adaptation = ContextAdaptation.in_context(self, a_class, a_selector, a_method)
    self.add_adaptation(context_adaptation)
  end

  def add_adaptation(&args)
    raise Exception, "add_adaptation takes 1 or 2 arguments" unless args.size == 1 || args.size == 2
    self.add_adaptation(args[0]) { raise Exception, "an adaptation of #{args[0].adapted_selector.to_s} in #{args[0].adapted_class.to_s} already exists for #{self.to_s}" } if args.size == 1
    existing_adaptation = @adaptations.index do |adaptation|
    adaptation.same_target?(args[0])
    end
    if existing_adaptation.nil?
      self.add_inexistent_adaptation(args[0])
      return self
    end
    existing_adaptation = @adaptations[existing_adaptation]
    action = yield
    if action == :overwrite
      self.remove_existing_adaptation(existing_adaptation)
      self.add_inexistent_adaptation(args[0])
    else
      raise Exception, "Unknown overriding action #{action.to_s}" unless action == :preserve
    end
  end

  def add_inexistent_adaptation(context_adaptation)
    raise Exception, "Attempt to add foreign adaptation." unless self == context_adaptation.context
    @adaptations.push(context_adaptation)
    self.manager.activate_adaptation(context_adaptation) if self.active?
  end

  def deactivate
    self.deactivate_adaptations if @count == 1
    super.deactivate
  end

  def deactivate_adaptations
    @adaptations.each do |i|
      self.manager.deactivate_adaptation(i)
    end
  end

  def discard
    super.discard
    @adaptations.clone.each do |i|
      self.remove_existing_adaptation(i)
    end
  end

  def remove_existing_adaptation(context_adaptation)
    raise Exception, "Request to remove foreign adaptation" unless self == context_adaptation.context
    self.manager.deactivate_adaptation(context_adaptation) if self.active?
    raise Exception, "Inconsistent context state" if @adaptations.delete(context_adaptation).nil?
  end

  def roll_back_adaptations
    deployed = self.manager.active_adaptations.select { |adaptation| adaptation.context == self }
    deployed.each do |adaptation|
      self.manager.deactivate_adaptation(adaptation)
    end
  end

end

class ContextAdaptation
  
  attr_accessor :context, :adapted_class, :adapted_selector, :adapted_implementation

  def self.in_context(*args)
    raise Exception, "in_context takes 4 arguments" unless args.size == 4
    adaptation = self.new
    adaptation.context=(args[0])
    adaptation.adapted_class=(args[1])
    adaptation.adapted_selector=(args[2])
    adaptation.adapted_implementation=(args[3])
    adaptation
  end

  def ==(other)
    self.context == other.context and
    self.adapted_class == other.adapted_class and
    self.adapted_selector == other.adapted_selector and
    self.adapted_implementation == other.adapted_implementation
  end

  def adapts_class?(a_class, a_symbol)
    self.adapted_class == a_class and self.adapted_selector == a_symbol
  end

  def deploy
    # wrong!
    @adapted_class = Hash.new if @adapted_class.nil?
    @adapted_class[@adapted_selector] = @adapted_implementation
  end

  def to_s
    "for #{@adapted_selector.to_s} of #{@adapted_class.to_s} using #{@adapted_implementation.nil? ? "no implementation" : @adapted_implementation.name.to_s} in #{@context.to_s}"
  end

  def same_target?(other)
    self.adapts_class(other.adapted_class, other.adapted_selector)
  end

end

class ContextManager5 < ContextManager4
  
  def initialize
    super.initialize
    @active_adaptations = Array.new
  end

  def activate_adaptation(context_adaptation)
    index = @active_adaptations.index do |adaptation|
      adaptation.same_target?(context_adaptation) && adaptation.context != Context.default
    end
    raise Exception, "Conflicting adaptation for #{context_adaptation.adapted_class.to_s} >> #{context_adaptation.adapted_selector.to_s}" if index.nil?
    @active_adaptations.push(context_adaptation)
    context_adaptation.deploy
  end

  def deactivate_adaptation(context_adaptation)
    raise Exception, "Attempt to deactivate unmanaged adaptation" if @active_adaptations.delete(context_adaptation).nil?
    default = Context.default.adaptations.index do |adaptation|
      adaptation.adapts_class?(context_adaptation.adapted_class, context_adaptation.adapted_selector)
    end
    raise Exception, "Could not find default behaviour for removed adaptation" if default.nil?
    Context.default.adaptations[default].deploy
  end

end

class Context < Context5
end
class ContextManager < ContextManager5
end
