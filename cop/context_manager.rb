#!/usr/bin/env ruby

class ContextManager
  
  @@default = nil

  attr_accessor :directory, :adaptations

  def initialize
    @directory = Hash.new
    @adaptations = Array.new
    @total_activations = 0
    @activation_stamps = Hash.new
    self.resolution_policy= self.age_resolution_policy
  end

  def discard_context(context)
    raise Exception "can't discard outside context manager" if context.manager != self
    raise Exception, "can't discard an active context" if context.active?
    @directory.delete(self)
    @activation_stamps.delete(context)
  end

  def activate_adaptation(context_adaptation)
    @adaptations.push(context_adaptation)
    self.deploy_best_adaptation_for(context_adaptation.adapted_class, context_adaptation.adapted_selector)
  end

  def deactivate_adaptation(context_adaptation)
    raise Exception, "can't deactivate unmanaged adaptation" if @adaptations.delete(context_adaptation).nil?
    self.deploy_best_adaptation_for(context_adaptation.adapted_class, context_adaptation.adapted_selector) unless @adaptations.empty?
  end

  def deploy_best_adaptation_for(a_class, a_symbol)
    self.adaptation_chain(a_class, a_symbol).first.deploy
  end

  def adaptation_chain(a_class, a_symbol)
    a = @adaptations.select do |adaptation|
      adaptation.adapts_class? a_class, a_symbol
    end
    raise Exception, "no adaptation found for #{a_class.to_s}.#{a_symbol.to_s}" if a.empty?
    a.sort do |a1, a2|
      @resolution_policy.call(a1.context, a2.context)
    end
  end

  def resolution_policy=(policy)
    @resolution_policy = policy
    @adaptations.each do |adaptation|
      self.deploy_best_adaptation_for(adaptation.adapted_class, adaptation.adapted_selector)
    end
  end

  def age_resolution_policy
    Proc.new { |a1, a2|
      (self.context_activation_age(a1) < self.context_activation_age(a2)) ? -1 : 1
    }
  end

  def context_activation_age(context)
    @total_activations - (@activation_stamps[context].nil? ? 0 : @activation_stamps[context])
  end

  def signal_activation_request(context)
    @total_activations += 1
    @activation_stamps[context] = @total_activations
  end

end
