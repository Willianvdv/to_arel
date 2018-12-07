module ToArel
  module Ast
    #:nodoc:
    class RawStmt
      include Contracts::Core
      include Contracts::Builtin

      attr_reader :stmt

      TYPE = StrictHash[{ 'RawStmt' => { 'stmt' => Ast::SelectStmt::TYPE } }]

      Contract TYPE => Any
      def initialize(data)
        @stmt = SelectStmt.new data['RawStmt']['stmt']
      end
    end
  end
end
