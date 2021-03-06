# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Accumulate the matching row(s) and calculate the final result.
  # @api private
  class Decision
    # Main method for making decisions without a path.
    #
    # @param table [CSVDecision::Table] Decision table.
    # @param input [Hash] Input hash (keys may or may not be symbolized)
    # @param symbolize_keys [Boolean] Set to false if keys are symbolized and it's
    #   OK to mutate the input hash. Otherwise a copy of the input hash is symbolized.
    # @return [Hash{Symbol=>Object}] Decision result.
    def self.make(table:, input:, symbolize_keys:)
      # Parse and transform the hash supplied as input
      data = Input.parse(table: table, input: input, symbolize_keys: symbolize_keys)

      # The decision object collects the results of the search and
      # calculates the final result.
      Decision.new(table: table).scan(data)
    end

    # @return [Boolean] True if a first match decision table.
    attr_reader :first_match

    # @return [CSVDecision::Table] Decision table object.
    attr_reader :table

    # @param table [CSVDecision::Table] Decision table being processed.
    def initialize(table:)
      # The result object is a hash of values, and each value will be an array if this is
      # a multi-row result for the +first_match: false+ option.
      @result = Result.new(table: table)
      @first_match = table.options[:first_match]
      @table = table
    end

    # Initialize the input data used to make the decision.
    #
    # @param data [Hash{Symbol=>Object}] Input hash data structure.
    # @return [void]
    def input(data)
      @result.input(data[:hash])

      # All rows picked by the matching process. An array if +first_match: false+,
      # otherwise a single row.
      @rows_picked = []

      @input = data
    end

    # Scan the decision table and produce an output decision.
    #
    # @param data [Hash{Symbol=>Object}] Input hash data structure.
    # @return (see .make)
    def scan(data)
      input(data)
      # Use the table's index if present
      @table.index ? index_scan : table_scan
    end

    #  Scan the index for a first match result.
    #
    # @param scan_cols [Hash{Integer=>Object}]
    # @param hash [Hash{Symbol=>Object}]
    # @param index_rows [Array<Integer>]
    # @return [Hash{Symbol=>Object}]
    def index_scan_first_match(scan_cols:, hash:, index_rows:)
      index_rows.each do |start_row, end_row|
        @table.each(start_row, end_row || start_row) do |row, index|
          next unless @table.scan_rows[index].match?(row: row, hash: hash, scan_cols: scan_cols)

          return @result.attributes if first_match_found(row)
        end
      end

      {}
    end

    #  Scan the index for an accumulated result.
    #
    # @param scan_cols [Hash{Integer=>Object}]
    # @param hash [Hash{Symbol=>Object}]
    # @param index_rows [Array<Integer>]
    # @return [Hash{Symbol=>Object}]
    def index_scan_accumulate(scan_cols:, hash:, index_rows:)
      index_rows.each do |start_row, end_row|
        @table.each(start_row, end_row || start_row) do |row, index|
          next unless @table.scan_rows[index].match?(row: row, hash: hash, scan_cols: scan_cols)

          # Accumulate output rows.
          @rows_picked << row
          @result.accumulate_outs(row)
        end
      end

      @rows_picked.empty? ? {} : accumulated_result
    end

    private

    # Use an index to scan the decision table up against the input hash.
    def index_scan_rows(rows:)
      if @first_match
        index_scan_first_match(scan_cols: @input[:scan_cols], hash: @input[:hash], index_rows: rows)
      else
        index_scan_accumulate(scan_cols: @input[:scan_cols], hash: @input[:hash], index_rows: rows)
      end
    end

    def scan_first_match(hash:, scan_cols:)
      @table.each do |row, index|
        next unless @table.scan_rows[index].match?(row: row, hash: hash, scan_cols: scan_cols)

        return @result.attributes if first_match_found(row)
      end

      {}
    end

    def scan_accumulate(hash:, scan_cols:)
      @table.each do |row, index|
        next unless @table.scan_rows[index].match?(row: row, hash: hash, scan_cols: scan_cols)

        # Accumulate output rows
        @rows_picked << row
        @result.accumulate_outs(row)
      end

      @rows_picked.empty? ? {} : accumulated_result
    end

    # Scan the decision table up against the input hash.
    def table_scan
      if @first_match
        scan_first_match(hash: @input[:hash], scan_cols:  @input[:scan_cols])
      else
        scan_accumulate(hash: @input[:hash], scan_cols:  @input[:scan_cols])
      end
    end

    # Use an index to scan the decision table up against the input hash.
    def index_scan
      # If the index lookup fails, there's no match.
      return {} unless (index_rows = Array(@table.index.hash[@input[:key]]))

      index_scan_rows(rows: index_rows)
    end

    def accumulated_result
      return @result.final_result unless @result.outs_functions
      return @result.eval_outs(@rows_picked.first) unless @result.multi_result

      multi_row_result
    end

    def multi_row_result
      # Scan each output column that contains functions
      @result.outs.each_pair { |col, column| eval_procs(col: col, column: column) if column.eval }

      @result.final_result
    end

    def eval_procs(col:, column:)
      @rows_picked.each_with_index do |row, index|
        cell = row[col]
        next unless cell.is_a?(Matchers::Proc)

        # Evaluate the proc and update the result
        @result.eval_cell_proc(proc: cell, column_name: column.name, index: index)
      end
    end

    def first_match_found(row)
      # This decision row may contain procs, which if present will need to be evaluated.
      # If this row contains if: columns then this row may be filtered out, in which case
      # this method call will return false.
      return eval_single_row(row) if @result.outs_functions

      # Common case is just copying output column values to the final result.
      @rows_picked = row
      @result.add_outs(row)
    end

    def eval_single_row(row)
      return false unless (result = @result.eval_outs(row))

      @rows_picked = row
      result
    end
  end
end