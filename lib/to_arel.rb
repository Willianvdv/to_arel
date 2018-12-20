require 'to_arel/version'
require 'arel'
require 'pg_query'

def symbolize_keys(hash)
  Hash[hash.map{|k, v| [k.to_sym, v]}]
end

#:nodoc:
module ToArel
  def self.to_arel(tree = @tree)
    tree.map do |item|
      Arelifier.from(item)
    end
  end

  module Arelifier
    extend self

    def from(item)
      arel_item(item)
    end

    def arel_item(item, context = nil)
      return if item.nil?
      # return item if item.is_a?(Integer)

      type = item.keys[0]
      node = item.values[0]

      case type
      when PgQuery::RAW_STMT
        arel_raw_stmt(node)
      when PgQuery::SELECT_STMT
        arel_select(node)
      else
        puts "----> I DO NOT KNOW -> type: #{type}; node: #{node}"
      end
    end

    def arel_select(node)
      binding.pry
    end

    def arel_raw_stmt(node)
      arel_item(node[PgQuery::STMT_FIELD])
    end
  end

  class Error < StandardError; end
  class MultiTableError < Error; end

  def self.parse(sql)
    tree = PgQuery.parse(sql).tree
    puts to_arel(tree)



    # raise 'cannot process more than 1 statement' if tree.length > 1

    # statement = tree.first
    #   .fetch('RawStmt')
    #   .fetch('stmt')

    # raise 'dunno how to handle more than 1 statement' if statement.keys.length > 1

    # manager_from_statement statement
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

    # from_clauses = ast.fetch('fromClause')
    # raise MultiTableError, 'Can not handle multiple tables' if from_clauses.length > 1
    # from_clause = from_clauses.first
    # table = RangeVar.new(**symbolize_keys(from_clause.fetch('RangeVar'))).to_arel

    # puts ast

    # target_lists = ast.fetch('targetList').map do |target_list|
    #   ResTarget.new(**symbolize_keys(target_list.fetch('ResTarget'))).to_arel
    # end

    # a = Arel::SelectManager.new table
    # b = a.project(target_lists)
    # binding.pry
  end
end
