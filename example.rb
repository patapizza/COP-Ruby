#!/usr/bin/env ruby

$: << "."

require "cop/context"

class House
  def entering(visitor)
    visitor.context.activate
  end
  def leaving(visitor)
    visitor.context.deactivate
  end
  def play_song
    "the hall of the mountain king (by default)"
  end
end

class Visitor
  attr_reader :context
  def initialize(name, song)
    @name = name
    @song = song
    @context = Context.named(name)
    @context.adapt_class(House, :play_song, lambda { |*args| "#{@song} (for #{self.to_s})" })
  end
  def to_s
    @name
  end
end

house = House.new
alice = Visitor.new("alice", "the imperial march")
john = Visitor.new("john", "nutcracker theme")

puts house.play_song
house.entering(alice)
puts house.play_song
house.entering(john)
puts house.play_song
house.leaving(john)
puts house.play_song
house.leaving(alice)
puts house.play_song

class HearingImpaired < Visitor
  def initialize(name)
    @name = name
    @context = Context.named(name)
    @context.adapt_class(House, :play_song, lambda { |*args| "#{Context.proceed} LOUDLY (for #{self.to_s})" })
  end
end

stan = HearingImpaired.new("stan")

puts house.play_song
house.entering(alice)
puts house.play_song
house.entering(stan)
puts house.play_song
house.leaving(stan)
puts house.play_song
house.leaving(alice)
puts house.play_song
