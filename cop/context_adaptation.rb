#!/usr/bin/env ruby

$: << ".."

require "cop/context"

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
      @adapted_class.send(:define_method, @adapted_selector, lambda do |args = x.parameters, ca = y|
        Context.stack= Context.stack.push(ca)
	r = x.call(args)
	Context.stack.pop()
	r
      end)
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
    "for #{@adapted_selector.to_s} of #{@adapted_class.to_s} using #{@adapted_implementation.nil? ? "no implementation" : @adapted_implementation.to_s} in #{@context.to_s}"
  end

end
