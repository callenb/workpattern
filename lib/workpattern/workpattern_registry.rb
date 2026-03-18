# frozen_string_literal: true

# WorkpatternRegistry is used to hold instances of the
# Workpattern class so they can be retrieved when required.
module WorkpatternRegistry
  # We use a hash to store instances: { "name" => instance }
  @registry = {}

  def self.register(workpattern)
    name = workpattern.name
    raise NameError, "Workpattern '#{name}' already exists" if @registry.key?(name)

    @registry[name] = workpattern
  end

  def self.find(name)
    @registry[name]
  end

  def self.all
    @registry.values
  end

  def self.clear
    @registry.clear
  end
end
