#!/usr/bin/env ruby

class PhoneCall
  
  attr_accessor :from

  def initialize(from)
    @from = from
  end
  
  def self.from(from)
    self.new(from)
  end

  def to_s
    "from #{ @from }"
  end

end
