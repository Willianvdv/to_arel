module ToArel
  module Ast
    #:nodoc:
    class SelectStmt
      include Contracts::Core
      include Contracts::Builtin

      attr_reader :target_list

      TYPE = {
        'SelectStmt' => {
          'targetList' => Array
        }
      }.freeze

      Contract TYPE => Any
      def initialize(data)
        @target_list = data['SelectStmt']['targetList']
      end
    end
  end
end
