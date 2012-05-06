#!/usr/bin/env ruby

require 'test/unit'
require "/home/lasher/prog/github/COP-Ruby/cop"
require '/home/lasher/prog/github/COP-Ruby/phone'

class Test5 < Test::Unit::TestCase

  def setup
    self unless Context.public_method_defined? "adapt_class"
    Context.default.deactivate
    Context.default.discard
    receive_method = Phone.allocate.method(:receive).to_proc
    advertise_method = Phone.allocate.method(:advertise).to_proc
    quiet = Context.named("quiet")
    quiet.adapt_class(Phone, :advertise, DiscretionPhoneExtension.allocate.method(:advertise_quietly).to_proc)
    off_hook = Context.named("off hook")
    off_hook.adapt_class(Phone, :advertise, MulticallPhoneExtension.allocate.method(:advertise_waiting_call).to_proc)
  end

  def teardown
    quiet.deactivate
    quiet.discard
    off_hook.deactivate
    off_hook.discard
    Context.default.deactivate
    Context.default.discard
    Phone.send(:define_method, :receive) do
      receive_method
    end
    Phone.send(:define_method, :advertise) do
      advertise_method
    end
    Phone.remove_method(:phony_advertise)
  end

  def test_adaptation_API
    assert(Context.public_method_defined? "adapt_class")
  end

  def test_conflicting_activation
    assert(!quiet.active?)
    assert_nothing_raised Exception do
      quiet.activate
    end
    assert(quiet.active?)
    assert(!off_hook.active?)
    assert_raise Exception do
      off_hook.activate
    end
    assert(!off_hook.active?)
  end

  def test_conflicting_adaptation
    assert_raise Exception do
      quiet.adapt_class(Phone, :advertise, DiscretionPhoneExtension.method(:advertise_discrete_beep).to_proc)
    end
  end

  def test_invalid_adaptation
    assert_raise Exception do
      Context.new.adapt_class(Phone, :phony_advertise, DiscretionPhoneExtension.method(:advertise_quietly).to_proc)
    end
  end

  def test_overriding_adaptation
    phone = Phone.new
    call = PhoneCall.from= "Bob"
    phone.receive(call)
    assert_equal(phone.advertise(call), "ringtone")
    quiet.activate
    assert_equal(phone.advertise(call), "vibrator")
    quiet.deactivate
    assert_equal(phone.advertise(call), "ringtone")
  end

end
