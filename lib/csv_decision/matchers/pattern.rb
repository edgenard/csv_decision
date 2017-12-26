# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  class Matchers
    # Match cell against a regular expression pattern - e.g., +=~ hot|col+ or +.*OPT.*+
    class Pattern < Matcher
      EXPLICIT_COMPARISON = Matchers.regexp("(?<comparator>=~|!~|!=)\\s*(?<value>\\S.*)")
      private_constant :EXPLICIT_COMPARISON

      IMPLICIT_COMPARISON = Matchers.regexp("(?<comparator>=~|!~|!=)?\\s*(?<value>\\S.*)")
      private_constant :IMPLICIT_COMPARISON

      # rubocop: disable Style/DoubleNegation
      PATTERN_LAMBDAS = {
        '!=' => proc { |pattern, value|   pattern != value }.freeze,
        '=~' => proc { |pattern, value| !!pattern.match(value) }.freeze,
        '!~' => proc { |pattern, value|  !pattern.match(value) }.freeze
      }.freeze
      private_constant :PATTERN_LAMBDAS
      # rubocop: enable Style/DoubleNegation

      def self.regexp?(cell:, explicit:)
        # By default a regexp pattern must use an explicit comparator
        match = explicit ? EXPLICIT_COMPARISON.match(cell) : IMPLICIT_COMPARISON.match(cell)
        return false if match.nil?

        comparator = match['comparator']

        # Comparator may be omitted if the regexp_explicit option is off.
        return false if explicit && comparator.nil?

        parse(comparator: comparator, value: match['value'])
      end
      private_class_method :regexp?

      def self.parse(comparator:, value:)
        return false if value.blank?

        # We cannot do a regexp comparison against a symbol name.
        # (Maybe we should add this feature?)
        return if value[0] == ':'

        # If no comparator then the implicit option must be on
        comparator = regexp_implicit(value) if comparator.nil?

        [comparator, value]
      end

      def self.regexp_implicit(value)
        # rubocop: disable Style/CaseEquality
        return unless /\W/ === value
        # rubocop: enable Style/CaseEquality

        # Make the implict comparator explict
        '=~'
      end

      def self.matches?(cell, regexp_explicit:)
        comparator, value = regexp?(cell: cell, explicit: regexp_explicit)

        # We could not find a regexp pattern - maybe it's a simple string or something else?
        return false unless comparator

        # No need for a regular expression if we have simple string inequality
        pattern = comparator == '!=' ? value : Matchers.regexp(value)

        Proc.with(type: :proc,
                  function: PATTERN_LAMBDAS[comparator].curry[pattern].freeze)
      end

      # @param options [Hash{Symbol=>Object}] Used to determine the value of regexp_implicit:.
      def initialize(options = {})
        # By default regexp's must have an explicit comparator
        @regexp_explicit = !options[:regexp_implicit]
      end

      # Recognise a regular expression pattern - e.g., +=~ on|off+ or +!~ OPT.*+.
      # If the option regexp_implicit: true has been set, then cells may omit the +=~+ comparator so long as they
      # contain non-word characters typically used in regular expressions such as +*+ and +.+.
      # @param (see Matchers::Matcher#matches?)
      # @return (see Matchers::Matcher#matches?)
      def matches?(cell)
        Pattern.matches?(cell, regexp_explicit: @regexp_explicit)
      end
    end
  end
end