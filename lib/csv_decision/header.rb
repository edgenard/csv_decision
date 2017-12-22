# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  module Header
    # Column header looks like IN :col_name or cond:
    COLUMN_TYPE = %r{
      \A(?<type>in|out|in/text|out/text|set|set/nil|set/blank|path|cond|if)
      \s*:\s*(?<name>\S?.*)\z
    }xi

    # These column types do not need a name
    COLUMN_TYPE_ANONYMOUS = Set.new(%i[path if cond]).freeze

    # More lenient than a Ruby method name -
    # any spaces will have been replaced with underscores
    COLUMN_NAME = %r{\A\w[\w:/!?]*\z}

    # Does this row contain a recognisable header cell?
    def self.row?(row)
      row.find { |cell| cell.match(COLUMN_TYPE) }
    end

    def self.strip_empty_columns(table:)
      empty_cols = empty_columns?(row: table.rows.first)
      Data.strip_columns(data: table.rows, empty_columns: empty_cols) unless empty_cols.empty?

      table.rows.shift
    end

    def self.empty_columns?(row:)
      return [] unless row

      result = []
      row.each_with_index { |cell, index| result << index if cell == '' }

      result
    end

    def self.column?(cell:)
      match = COLUMN_TYPE.match(cell)
      raise CellValidationError, 'column name is not well formed' unless match

      column_type = match['type']&.downcase&.to_sym
      column_name = column_name(type: column_type, name: match['name'])

      [column_type, column_name]
    rescue CellValidationError => exp
      raise CellValidationError,
            "header column '#{cell}' is not valid as #{exp.message}"
    end

    def self.column_name(type:, name:)
      return format_column_name(name) if name.present?
      return if COLUMN_TYPE_ANONYMOUS.member?(type)

      raise CellValidationError, 'the column name is missing'
    end

    def self.format_column_name(name)
      column_name = name.strip.tr("\s", '_')

      return column_name.to_sym if COLUMN_NAME.match(column_name)

      raise CellValidationError, "column name '#{name}' contains invalid characters"
    end

    # Returns the normalized column type, along with an indication if
    # the column is text only
    def self.column_type(type)
      case type
      when :'in/text'
        [:in, true]

      when :cond
        [:in, false]

      when :'out/text'
        [:out, true]

      # Column may turn out to be text-only, or not
      else
        [type, nil]
      end
    end

    def self.dictionary(row:)
      # The input and output columns, where the key is the row's array
      # column index. Note that input and output columns can be interspersed,
      # and need not have unique names.
      dictionary = {
        ins: {},
        outs: {},
        # Path for the input hash - optional
        path: {},
        # Hash of columns that require defaults to be set
        defaults: {}
      }
      return dictionary unless row

      row.each_with_index do |cell, index|
        dictionary = parse_cell(cell: cell, index: index, dictionary: dictionary)
      end

      dictionary
    end

    def self.parse_cell(cell:, index:, dictionary:)
      column_type, column_name = Header.column?(cell: cell)

      type, text_only = Header.column_type(column_type)

      dictionary_entry(dictionary: dictionary,
                       type: type,
                       entry: { name: column_name, text_only: text_only },
                       index: index)
    end
    private_class_method :parse_cell

    def self.dictionary_entry(dictionary:, type:, entry:, index:)
      case type
      # Header column that has a function for setting the value
      when :set, :'set/nil', :'set/blank'
        # Default function will set the input value unconditionally or conditionally
        dictionary[:defaults][index] =
          { name: entry[:name], function: nil, if: default_if(type) }

        # Treat set: as an in: column
        dictionary[:ins][index] = entry

      when :in
        dictionary[:ins][index] = entry

      when :out
        dictionary[:outs][index] = entry

      else
        raise "internal error - column type #{type} not recognised"
      end

      dictionary
    end
    private_class_method :dictionary_entry

    def self.default_if(type)
      return nil if type == :set
      return :nil? if type == :'set/nil'
      :blank?
    end
  end
end