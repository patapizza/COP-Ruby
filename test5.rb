#!/usr/bin/env ruby

require 'test/unit'
require "/home/lasher/prog/github/COP-Ruby/cop"
require "/home/lasher/prog/github/COP-Ruby/phone"

class Test5 < Test::Unit::TestCase

  def setup
    self unless Context.public_method_defined? "adapt_class"
    Context.default.deactivate
    Context.default.discard
    @receive_method = Phone.new.method(:receive).to_proc
    @advertise_method = Phone.new.method(:advertise).to_proc
    @quiet = Context.named("quiet")
    @quiet.adapt_class(Phone, :advertise) { |x| "vibrator" }
    @off_hook = Context.named("off hook")
    @off_hook.adapt_class(Phone, :advertise) { |x| "call waiting call" }
  end

  def teardown
    @quiet.deactivate
    @quiet.discard
    @off_hook.deactivate
    @off_hook.discard
    Context.default.deactivate
    Context.default.discard
    x = @receive_method
    Phone.send(:define_method, :receive) do |args = x.parameters|
      x.call(args)
    end
    x = @advertise_method
    Phone.send(:define_method, :advertise) do |args = x.parameters|
      x.call(args)
    end
  end

  def test_adaptation_API
    assert(Context.public_method_defined? "adapt_class")
  end

  def test_conflicting_activation
    assert(!@quiet.active?)
    assert_nothing_raised Exception do
      @quiet.activate
    end
    assert(@quiet.active?)
    assert(!@off_hook.active?)
    assert_raise Exception do
      @off_hook.activate
    end
    assert(!@off_hook.active?)
  end

  def test_conflicting_adaptation
    assert_raise Exception do
      @quiet.adapt_class(Phone, :advertise) { |x| "discrete beep" }
    end
  end

  def test_invalid_adaptation
    assert_raise Exception do
      Context.new.adapt_class(Phone, :phony_advertise) { |x| "vibrator" }
    end
  end

  def test_overriding_adaptation
    phone = Phone.new
    call = PhoneCall.new("Bob")
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    @quiet.activate
    assert_equal(phone.advertise(call), "vibrator")
    @quiet.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

end
