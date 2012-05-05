#!/usr/local/bin/ruby

require 'test/unit'
require 'framework'

class Tests < Test::Unit::TestCase

  def setup
    @context0 = Context.new
    @context1 = Context.new
    @context2 = Context.default
    @context3 = Context.new
    @context4 = Context.new
  end

  def test_activation
    assert(!@context0.active?)
    assert_equal(@context0.activate, @context0)
    assert(@context0.active?)
    assert_equal(@context0.deactivate, @context0)
    assert(!@context0.active?)
  end

  def test_anonymous_context_name
    assert(Context.public_method_defined? "name")
    assert(Context.new.name.nil?)
    assert_equal(Context.new.to_s, "anonymous context")
  end

  def test_context_creation
    assert(@context1.is_a? Context)
    assert(@context1.active?.is_a?(TrueClass) || @context1.active?.is_a?(FalseClass))
    assert(!@context1.active?)
  end

  def test_context_disposal
    assert(Context.public_method_defined? "discard")
    assert(Context.default.active?)
    assert_raise Error do
      Context.default.discard
    end
    assert(!Context.default.active?)
    assert_nothing_raised Error do
      Context.default.discard
    end
    assert_nothing_raised Error do
      test_default_context
    end
    assert(!Context.default, @context2)
  end

  def test_context_protocol
    assert_nothing_raised NameError do
      Context
    end
    assert(Context.is_a? Class)
    assert(Context.public_method_defined? "activate")
    assert(Context.public_method_defined? "deactivate")
    assert(Context.public_method_defined? "active?")
  end

  def test_default_context
    assert(Context.public_class_method.public_method_defined? "default")
    assert(!Context.default.nil?)
    assert(Context.default.is_a? Context)
    assert(Context.default.active?)
  end

  def test_default_context_name
    assert_equal(Context.default.name, "default")
    assert_equal(Context.default.to_s, "default context")
  end

  def test_redundant_activation
    assert(!@context3.active?)
    10.times { @context3.activate }
    assert(@context3.active?)
    9.times { @context3.deactivate }
    assert(@context3.active?)
    @context3.deactivate
    assert(!@context3.active?)
  end

  def test_redundant_deactivation
    assert(!@context4.active?)
    3.times { @context4. activate }
    assert(@context4.active?)
    9.times { @context4.deactivate }
    assert(!@context4.active?)
    @context4.activate
    assert(@context4.active?)
    @context4.deactivate
    assert(!@context4.active?)
  end

end
