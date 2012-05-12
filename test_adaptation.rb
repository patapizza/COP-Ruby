#!/usr/bin/env ruby

require "test/unit"
require "./cop"
require "./phone"

class COPAdaptationTest < Test::Unit::TestCase

  def setup
    return self unless Context.public_method_defined? :adapt_class
    Context.default.deactivate
    Context.default.discard
    @quiet_context = Context.named("quiet")
    @quiet_context.adapt_class(Phone, :advertise, lambda { |*args| "vibrator" })
    @offhook_context = Context.named("off hook")
    @offhook_context.adapt_class(Phone, :advertise, lambda { |*args| "call waiting signal" })
  end

  def teardown
    Context.default.deactivate
    Context.default.discard
  end

  def test_adaptation_api
    assert(Context.public_method_defined? :adapt_class)
  end

  def test_conflicting_activation
    assert(!@quiet_context.active?)
    assert_nothing_raised Exception do
      @quiet_context.activate
    end
    assert(@quiet_context.active?)
    assert(!@offhook_context.active?)
    # The following has been made possible with composition of adaptations
    #assert_raise Exception do
    #  @offhook_context.activate
    #end
    #assert(!@offhook_context.active?)
    @quiet_context.deactivate
  end

  def test_conflicting_adaptation
    assert_raise Exception do
      @quiet_context.adapt_class(Phone, :advertise, lambda { |*args| "vibrator" })
    end
  end

  def test_invalid_adaptation
    assert_raise Exception do
      Context.new.adapt_class(Phone, :phony_advertise, lambda { |*args| "vibrator" })
    end
  end

  def test_overriding_adaptation
    phone = Phone.new
    call = PhoneCall.new("Bob")
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    @quiet_context.activate
    assert_equal(phone.advertise(call), "vibrator")
    @quiet_context.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

end
