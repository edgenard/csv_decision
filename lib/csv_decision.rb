# frozen_string_literal: true\


require 'active_support/core_ext/object'
require_relative '../lib/csv_decision/parse'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # @return [String] gem project's root directory
  def self.root
    File.dirname __dir__
  end

  autoload :Data,     'csv_decision/data'
  autoload :Columns,  'csv_decision/columns'
  autoload :Header,   'csv_decision/header'
  autoload :Matchers, 'csv_decision/matchers'
  autoload :Options,  'csv_decision/options'
  autoload :Parse,    'csv_decision/parse'
  autoload :Table,    'csv_decision/table'

  module Matchers
    autoload :Pattern,   'csv_decision/matchers/pattern'
  end
end