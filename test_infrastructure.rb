#!/usr/bin/env ruby

require "test/unit"
require "./cop"

class COPInfrastructureTest < Test::Unit::TestCase

  def test_activation
    context = Context.new
    assert(!context.active?)
    assert_equal(context.activate, context)
    assert(context.active?)
    assert_equal(context.deactivate, context)
    assert(!context.active?)
  end

  def test_anonymous_context
    assert(Context.public_method_defined? :name)
    assert(Context.new.name.nil?)
    assert_equal(Context.new.to_s, "anonymous context")
  end

  def test_context_creation
    context = Context.new
    assert(context.is_a? Context)
    assert((context.active?.is_a? TrueClass) || (context.active?.is_a? FalseClass))
    assert(!context.active?)
  end

  def test_context_disposal
    context = Context.default
    assert(Context.public_method_defined? :discard)
    assert(Context.default.active?)
    assert_raise Exception do
      Context.default.discard
    end
    Context.default.deactivate
    assert(!Context.default.active?)
    assert_nothing_raised Exception do
      Context.default.discard
    end
    assert_nothing_raised Exception do
      test_default_context
    end
    assert(Context.default != context)
  end

  def test_context_protocol
    assert_nothing_raised NameError do
      Context
    end
    assert(Context.is_a? Class)
    assert(Context.public_method_defined? :activate)
    assert(Context.public_method_defined? :deactivate)
    assert(Context.public_method_defined? :active?)
  end

  def test_default_context
    assert(Context.singleton_methods.include? :default)
    assert_not_nil(Context.default)
    assert(Context.default.is_a? Context)
    assert(Context.default.active?)
  end

  def test_default_context_name
    assert_equal(Context.default.name, "default")
    assert_equal(Context.default.to_s, "default context")
  end

  def test_redundant_activation
    context = Context.new
    assert(!context.active?)
    10.times do
      context.activate
    end
    assert(context.active?)
    9.times do
      context.deactivate
    end
    assert(context.active?)
    context.deactivate
    assert(!context.active?)
  end

  def test_redundant_deactivation
    context = Context.new
    assert(!context.active?)
    3.times do
      context.activate
    end
    assert(context.active?)
    9.times do
      context.deactivate
    end
    assert(!context.active?)
    context.activate
    assert(context.active?)
    context.deactivate
    assert(!context.active?)
  end

end
