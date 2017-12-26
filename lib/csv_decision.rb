# frozen_string_literal: true\

require 'active_support/core_ext/object'
require 'csv_decision/parse'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # @return [String] gem project's root directory
  def self.root
    File.dirname __dir__
  end

  autoload :Constant,   'csv_decision/constant'
  autoload :Data,       'csv_decision/data'
  autoload :Decide,     'csv_decision/decide'
  autoload :Decision,   'csv_decision/decision'
  autoload :Columns,    'csv_decision/columns'
  autoload :Function,   'csv_decision/function'
  autoload :Header,     'csv_decision/header'
  autoload :Input,      'csv_decision/input'
  autoload :Load,       'csv_decision/load'
  autoload :Matchers,   'csv_decision/matchers'
  autoload :Options,    'csv_decision/options'
  autoload :Parse,      'csv_decision/parse'
  autoload :ScanRow,    'csv_decision/scan_row'
  autoload :Symbol,     'csv_decision/symbol'
  autoload :Table,      'csv_decision/table'

  class Matchers
    autoload :Constant,      'csv_decision/matchers/constant'
    autoload :Function,      'csv_decision/matchers/function'
    autoload :Numeric,       'csv_decision/matchers/numeric'
    autoload :Pattern,       'csv_decision/matchers/pattern'
    autoload :Range,         'csv_decision/matchers/range'
    autoload :Symbol,        'csv_decision/matchers/symbol'
  end
end