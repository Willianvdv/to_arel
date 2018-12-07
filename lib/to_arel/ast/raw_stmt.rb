module ToArel
  module Ast
    class RawStmt
      include Contracts::Core
      include Contracts::Builtin

      attr_reader :stmt

      Type = StrictHash[{ "RawStmt" => { "stmt" => Ast::SelectStmt::Type } }]

      Contract Type => nil
      def initialize(data)
        @stmt = SelectStmt.new data['RawStmt']['stmt']
        nil
      end
    end
  end
end
