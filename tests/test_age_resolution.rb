#!/usr/bin/env ruby

$: << ".."

require "cop/context"
require "phone/phone"
require "phone/phone_call"
require "tests/test_composition"

class COPAgeResolutionTest < COPCompositionTest

  def setup
    super
  end

  def teardown
    super
  end

  def test_conflicting_activation
    @quiet_context.activate
    assert_nothing_raised Exception do
      @offhook_context.activate
    end
    @offhook_context.deactivate
    @quiet_context.deactivate
  end

  def test_context_age
    assert(Context.default.active?)
    assert(!@quiet_context.active?)
    assert(!@screening_context.active?)
    @screening_context.activate
    assert(@screening_context.activation_age < Context.default.activation_age)
    @quiet_context.activate
    assert(@quiet_context.activation_age < @screening_context.activation_age)
    assert(@screening_context.activation_age < Context.default.activation_age)
    @quiet_context.deactivate
    @screening_context.deactivate
    @screening_context.activate
    assert(@screening_context.activation_age < @quiet_context.activation_age)
    @screening_context.deactivate
  end
  
  def test_context_protocol
    assert(Context.public_method_defined? :activation_age)
    assert(Context.default.activation_age.is_a? Fixnum)
  end

  def test_interleaved_activation
    phone = Phone.new
    call = PhoneCall.from("Alice")
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    @quiet_context.activate
    assert_equal(phone.advertise(call), "vibrator")
    @screening_context.activate
    assert_equal(phone.advertise(call), "vibrator with screening")
    @quiet_context.deactivate
    assert_equal(phone.advertise(call), "ringtone with screening")
    @screening_context.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

  def test_nested_activation
    phone = Phone.new
    call = PhoneCall.from("Alice")
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    @quiet_context.activate
    assert_equal(phone.advertise(call), "vibrator")
    @screening_context.activate
    assert_equal(phone.advertise(call), "vibrator with screening")
    @screening_context.deactivate
    assert_equal(phone.advertise(call), "vibrator")
    @quiet_context.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

end
