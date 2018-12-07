module ToArel
  module Ast
    class SelectStmt
      include Contracts::Core
      include Contracts::Builtin

      attr_reader :targetList

      Type = {
        "SelectStmt" => {
          "targetList" => Array
        }
      }

      Contract Type => nil
      def initialize(data)
        @targetList = data['SelectStmt']['targetList']
        nil
      end
    end
  end
end
