#!/usr/bin/env ruby

class PhoneExtension
end

class DiscretionPhoneExtension < PhoneExtension

  def advertise_discrete_beep(call)
    "discrete beep"
  end

  def advertise_quietly(call)
    "vibrator"
  end

end

class MulticallPhoneExtension < PhoneExtension
  
  def advertise_waiting_call(call)
    "call waiting signal"
  end

end

class ScreeningPhoneExtension < PhoneExtension

  def advertise_with_screening(call)
  	"#{Context.proceed} with screening"
  end

end
