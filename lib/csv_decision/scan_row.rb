# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Data row object indicating which columns are constants versus procs.
  # @api private
  class ScanRow
    # These column types cannot have constants in their data cells.
    NO_CONSTANTS = Set.new(%i[guard if]).freeze
    private_constant :NO_CONSTANTS

    # Scan the table cell against all matches.
    #
    # @param columns [Hash{Integer=>Dictionary::Entry}] Column dictionary entry.
    # @param matchers [Array<Matchers::Matcher>]
    # @param cell [String]
    # @return [false, Matchers::Proc]
    def self.scan(path:, columns:, col:, matchers:, cell:)
      return false if cell == ''

      proc = scan_matchers(path: path, columns: columns, col: col, matchers: matchers, cell: cell)
      return proc if proc

      # Must be a simple string constant - this is OK except for a certain column types.
      invalid_constant?(type: :constant, column: columns[col])
    end

    def self.scan_matchers(path:, columns:, col:, matchers:, cell:)
      column = columns[col]

      # An if: guard looks at the flat output hash
      path = column.type == :if ? [] : path

      matchers.each do |matcher|
        # Guard function only accepts the same matchers as an output column.
        next if guard_ins_matcher?(column, matcher)

        proc = scan_proc(column: column, cell: cell, matcher: matcher, path: path)
        return proc if proc
      end

      # Must be a string constant
      false
    end
    private_class_method :scan_matchers

    # A guard column can only use output matchers
    def self.guard_ins_matcher?(column, matcher)
      column.type == :guard && !matcher.outs?
    end
    private_class_method :guard_ins_matcher?

    def self.scan_proc(column:, cell:, matcher:, path:)
      proc = matcher.matches?(cell, path)
      invalid_constant?(type: proc.type, column: column) if proc

      proc
    end
    private_class_method :scan_proc

    def self.invalid_constant?(type:, column:)
      return false unless type == :constant && NO_CONSTANTS.member?(column.type)

      raise CellValidationError, "#{column.type}: column cannot contain constants"
    end
    private_class_method :invalid_constant?

    # @return [Array<Integer>] Column indices for simple constants.
    attr_accessor :constants

    # @return [Array<Integer>] Column indices for Proc objects.
    attr_reader :procs

    def initialize(columns, path = [])
      @constants = []
      @procs = []
      @path = path
      @columns = columns
    end

    # Scan all the specified +columns+ (e.g., inputs) in the given +data+ row using the +matchers+
    # array supplied.
    #
    # @param row [Array<String>] Data row - still just all string constants.
    # @param columns [Array<Columns::Entry>] Array of column dictionary entries.
    # @param matchers [Array<Matchers::Matcher>] Array of table cell matchers.
    # @return [Array] Data row with anything not a string constant replaced with a Proc or a
    #   non-string constant.
    def scan_columns(row:, columns:, matchers:)
      columns.each_pair do |col, column|
        cell = row[col]

        # An empty input cell matches everything, and so never needs to be scanned,
        # but it cannot be indexed either.
        next column.indexed = false if cell == '' && column.ins?

        # If the column is text only then no special matchers need be used.
        next @constants << col if column.eval == false

        # Need to scan the cell against all matchers, and possibly overwrite
        # the cell contents with a Matchers::Proc value.
        row[col] = scan_cell(columns: columns, col: col, matchers: matchers, cell: cell)
      end

      row
    end

    # Match cells in the input hash against a decision table row.
    # @param row (see ScanRow.scan_columns)
    # @param hash (see Decision#row_scan)
    # @return [Boolean] True for a match, false otherwise.
    def match?(row:, scan_cols:, hash:)
      # If this row has a path, then need a different algorithm
      return match_path?(row: row, hash: hash) unless @path.empty?

      # Check any table row cell constants first, and maybe fail fast...
      return false if @constants.any? { |col| row[col] != scan_cols[col] }

      # These table row cells are Proc objects which need evaluating and
      # must all return a truthy value.
      @procs.all? { |col| row[col].call(value: scan_cols[col], hash: hash) }
    end

    private

    def match_path?(row:, hash:)
      path = hash.dig(*@path)
      return unless path.is_a?(::Hash)

      # Check any table row cell constants first, and maybe fail fast...
      return false if @constants.any? { |col| row[col] != path[@columns[col].name] }

      # These table row cells are Proc objects which need evaluating and
      # must all return a truthy value.
      @procs.all? { |col| row[col].call(value: path[@columns[col].name], hash: hash) }
    end

    def scan_cell(columns:, col:, matchers:, cell:)
      column = columns[col]

      # Scan the cell against all the matchers
      proc = ScanRow.scan(path: @path, columns: columns, col: col, matchers: matchers, cell: cell)

      return set(proc: proc, col: col, column: column) if proc

      # Just a plain constant
      @constants << col
      cell
    end

    def set(proc:, col:, column:)
      # Unbox a constant
      if proc.type == :constant
        @constants << col
        return proc.function
      end

      @procs << col
      column.indexed = false
      proc
    end
  end
end