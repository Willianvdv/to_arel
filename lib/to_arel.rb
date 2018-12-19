require 'to_arel/version'
require 'arel'
require 'pg_query'

def symbolize_keys(hash)
  Hash[hash.map{|k, v| [k.to_sym, v]}]
end

#:nodoc:
module ToArel
  module Nodes
    class Node; end

    class ColumnRef < Node
      # https://doxygen.postgresql.org/structColumnRef.html

      def initialize(fields:, location:)
        @fields = fields # field names (Value strings) or A_Star
        @location = location
      end

      def to_arel
        # binding.pry

        # TODO: CHECK IF THE FIELD IS A STRING
        # ? Arel::Attributes.for(X)
        # Arel::Attributes::String.new nil, 'id'

        Arel.star
      end
    end
  end

  class ResTarget
    # https://doxygen.postgresql.org/structResTarget.html

    def initialize(name: nil, indirection: nil, val: nil, location:)
      @name = name
      @indirection = indirection
      @location = location

      @val = val.map do |k, v|
        # TODO: CHECK IF K == COLUMNREF
        Nodes::ColumnRef.new **symbolize_keys(v)
      end
    end

    def to_arel
      @val.map &:to_arel
    end
  end

  class RangeVar
    # https://doxygen.postgresql.org/structRangeVar.html

    def initialize(relname:, inh:, relpersistence:, location:)
      @relname = relname
      @inh = inh
      @relpersistence = relpersistence
      @location = location
    end

    def to_arel
      Arel::Table.new @relname
    end
  end

  class Error < StandardError; end
  class MultiTableError < Error; end

  def self.parse(sql)
    tree = PgQuery.parse(sql).tree

    raise 'cannot process more than 1 statement' if tree.length > 1

    statement = tree.first
      .fetch('RawStmt')
      .fetch('stmt')

    raise 'dunno how to handle more than 1 statement' if statement.keys.length > 1

    manager_from_statement statement
  end

  def self.manager_from_statement(statement)
    type = statement.keys.first
    ast = statement[type]

    case type
    when 'SelectStmt'
      create_select_manager(ast)
    else
      raise "unknown statement type `#{type}`"
    end
  end

  def self.create_select_manager(ast)
    from_clauses = ast.fetch('fromClause')
    raise MultiTableError, 'Can not handle multiple tables' if from_clauses.length > 1
    from_clause = from_clauses.first
    table = RangeVar.new(**symbolize_keys(from_clause.fetch('RangeVar'))).to_arel

    puts ast

    target_lists = ast.fetch('targetList').map do |target_list|
      ResTarget.new(**symbolize_keys(target_list.fetch('ResTarget'))).to_arel
    end

    a = Arel::SelectManager.new table
    b = a.project(target_lists)
    binding.pry
  end
end
