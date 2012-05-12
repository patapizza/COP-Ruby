#!/usr/bin/env ruby

class Phone

  attr_accessor :active_call, :incoming_calls, :missed_calls, :ongoing_calls, :terminated_calls

  def initialize
    @incoming_calls = Array.new
    @ongoing_calls = Array.new
    @terminated_calls = Array.new
    @missed_calls = Array.new
  end

  def advertise(call)
    "ringtone"
  end

  def answer(*args)
    if args.size == 0
      next_call = @incoming_calls[0]
      raise Exception if next_call.nil?
      self.answer(next_call)
    else
      raise Exception if @incoming_calls.delete(args[0]).nil?
      self.suspend
      @ongoing_calls.push(args[0])
      self.resume(args[0])
    end
  end

  def hang_up(*args)
    if args.size == 0
      raise Exception if self.active_call.nil?
      self.hang_up(@active_call)
    else
      raise Exception if @ongoing_calls.delete(args[0]).nil?
      self.suspend if @active_call == args[0]
      @terminated_calls.push(args[0])
    end
  end

  def miss(call)
    raise Exception if @incoming_calls.delete(call).nil?
    @missed_calls.push(call)
  end

  def receive(call)
    @incoming_calls.push(call)
    self.advertise(call)
  end

  def resume(call)
    raise Exception if !@ongoing_calls.include? call 
    @active_call = call
  end

  def suspend
    @active_call = nil
  end

end
