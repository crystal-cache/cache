require "spec"
require "../src/cache"

module Spec
  # :nodoc:
  struct BeEmptyExpectation
    def match(actual_value)
      actual_value.empty?
    end

    def failure_message(actual_value)
      "Expected: #{actual_value.inspect} to be empty"
    end

    def negative_failure_message(actual_value)
      "Expected: #{actual_value.inspect} not to be empty"
    end
  end

  module Expectations
    # Creates an `Expectation` that  passes if actual is empty (`.empty?`).
    def be_empty
      Spec::BeEmptyExpectation.new
    end
  end
end
