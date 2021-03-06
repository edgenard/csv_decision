# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Validate and normalize the options values supplied.
  # @api private
  module Options
    # Specialized cell value matchers beyond simple string compares.
    # By default all these matchers are tried in the specified order on all
    # input data cells.
    DEFAULT_MATCHERS = [
      Matchers::Range,
      Matchers::Numeric,
      Matchers::Pattern,
      Matchers::Constant,
      Matchers::Symbol,
      Matchers::Guard
    ].freeze

    # All valid CSVDecision::parse options with their default values.
    VALID = {
      first_match: true,
      regexp_implicit: false,
      text_only: false,
      matchers: DEFAULT_MATCHERS
    }.freeze
    private_constant :VALID

    # These options may appear in the CSV file before the header row.
    # They get converted to a normalized option key value pair.
    CSV_NAMES = {
      first_match: [:first_match, true], accumulate: [:first_match, false],
      regexp_implicit: [:regexp_implicit, true],
      text_only: [:text_only, true], string_search: [:text_only, true]
    }.freeze
    private_constant :CSV_NAMES

    # Validate options and supply default values for any options not explicitly set.
    #
    # @param options [Hash] Input options hash supplied by the user.
    # @return [Hash] Options hash filled in with all required values, defaulted if necessary.
    # @raise [CellValidationError] For invalid option keys.
    def self.normalize(options)
      validate(options)
      default(options)
    end

    # Read any options supplied in the CSV file placed before the header row.
    #
    # @param rows [Array<Array<String>>] Table data rows.
    # @param options [Hash] Input options hash built so far.
    # @return [Hash] Options hash overridden with any values found in the CSV file.
    def self.from_csv(rows:, options:)
      row = rows.first
      return options if row.nil?

      # Have we hit the header row?
      return options if Header.row?(row)

      # Scan each cell looking for valid option values
      options = scan_cells(row: row, options: options)

      rows.shift
      from_csv(rows: rows, options: options)
    end

    def self.scan_cells(row:, options:)
      # Scan each cell looking for valid option values
      row.each do |cell|
        next if cell == ''

        key, value = option?(cell)
        options[key] = value if key
      end

      options
    end
    private_class_method :scan_cells

    def self.default(options)
      result = options.dup

      # The user may override the list of matchers to be used
      result[:matchers] = matchers(result)

      # Supply any missing options with default values
      VALID.each_pair do |key, value|
        next if result.key?(key)
        result[key] = value
      end

      result
    end
    private_class_method :default

    def self.matchers(options)
      return [] if options.key?(:matchers) && !options[:matchers]
      return [] if options[:text_only]
      return DEFAULT_MATCHERS unless options.key?(:matchers)

      options[:matchers]
    end
    private_class_method :matchers

    def self.option?(cell)
      key = cell.strip.downcase.to_sym

      CSV_NAMES[key]
    end
    private_class_method :option?

    def self.validate(options)
      invalid_options = options.keys - VALID.keys

      return if invalid_options.empty?

      raise CellValidationError, "invalid option(s) supplied: #{invalid_options.inspect}"
    end
    private_class_method :validate
  end
end