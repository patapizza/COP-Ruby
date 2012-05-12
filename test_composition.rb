#!/usr/bin/env ruby

require "./cop"
require "./phone"
require "./test_adaptation"

class COPCompositionTest < COPAdaptationTest

  def setup
    super
    @screening_context = Context.named("screening")
    @screening_context.adapt_class(Phone, :advertise, lambda { |*args| "#{Context.proceed} with screening" })
  end

  def teardown
    @screening_context.deactivate
    @screening_context.discard
    super
  end

  def test_invalid_proceed
    assert_raise Exception do
      Context.proceed
    end
  end

  def test_nested_activation
    phone = Phone.new
    call = PhoneCall.new("Alice")
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    @screening_context.activate
    assert_equal(phone.advertise(call), "ringtone with screening")
    @screening_context.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

end
