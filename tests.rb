#!/usr/bin/env ruby

require 'test/unit'
require "./cop"
require "./phone"

class Test4 < Test::Unit::TestCase

  def setup
    @context = Context.new
  end

  def test_activation
    assert(!@context.active?)
    assert_equal(@context.activate, @context)
    assert(@context.active?)
    assert_equal(@context.deactivate, @context)
    assert(!@context.active?)
  end

  def test_anonymous_context_name
    assert(Context.public_method_defined? "name")
    assert(Context.new.name.nil?)
    assert_equal(Context.new.to_s, "anonymous context")
  end

  def test_context_creation
    assert(@context.is_a? Context)
    assert(@context.active?.is_a?(TrueClass) || @context.active?.is_a?(FalseClass))
    assert(!@context.active?)
  end

  def test_context_disposal
    context = Context.default
    assert(Context.public_method_defined? "discard")
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
    assert(Context.public_method_defined? "activate")
    assert(Context.public_method_defined? "deactivate")
    assert(Context.public_method_defined? "active?")
  end

  def test_default_context
    assert(Context.singleton_methods.include? :default)
    assert(!Context.default.nil?)
    assert(Context.default.is_a? Context)
    assert(Context.default.active?)
  end

  def test_default_context_name
    assert_equal(Context.default.name, "default")
    assert_equal(Context.default.to_s, "default context")
  end

  def test_redundant_activation
    assert(!@context.active?)
    10.times { @context.activate }
    assert(@context.active?)
    9.times { @context.deactivate }
    assert(@context.active?)
    @context.deactivate
    assert(!@context.active?)
  end

  def test_redundant_deactivation
    assert(!@context.active?)
    3.times { @context. activate }
    assert(@context.active?)
    9.times { @context.deactivate }
    assert(!@context.active?)
    @context.activate
    assert(@context.active?)
    @context.deactivate
    assert(!@context.active?)
  end

  def test_adaptation
    @context.deactivate
    assert(Context.public_method_defined? "adapt_class")
    @context = Context.named("silent")
    assert(!@context.active?)
    @context.adapt_class(Phone, :advertise, lambda { |x| "vibrator" })
    assert(!@context.active?)
    phone = Phone.new
    call = PhoneCall.new("Alice")
    assert_equal(phone.advertise(call), "ringtone")
    @context.activate
    assert_equal(phone.advertise(call), "vibrator")
    @context.deactivate
    assert_equal(phone.advertise(call), "ringtone")
    assert_nothing_raised Exception do
      @context.discard
    end
    assert_equal(phone.advertise(call), "ringtone")
  end

  def test_composition
    @context = Context.named("screening")
    assert_raise Exception do
      Context.proceed
    end
    @context.adapt_class(Phone, :suspend, lambda { |*args| self })
    @context.adapt_class(Phone, :advertise, lambda { |*args| "#{Context.proceed} with screening" })
    phone = Phone.new
    call = PhoneCall.new("Alice")
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    @context.activate
    assert_equal(phone.advertise(call), "ringtone with screening")
    phone.suspend
    @context.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

  def test_age_resolution_policy
    assert(Context.public_method_defined? "activation_age")
    Context.default.manager.resolution_policy= Context.default.manager.age_resolution_policy
    assert(Context.default.active?)
    assert(!@context.active?)
    @context.activate
    assert(@context.activation_age < Context.default.activation_age)
  end

end
