require 'arel'
require 'contracts'
require 'pg_query'

require 'to_arel/version'
require 'to_arel/ast/select_stmt'
require 'to_arel/ast/raw_stmt'

#:nodoc:
module ToArel
  include Contracts::Core
  include Contracts::Builtin

  class Error < StandardError; end

  Contract String => Arel::SelectManager
  def self.parse(sql)
    tree = parse_sql(sql)

    # raise 'cannot process more than 1 statement' if tree.length > 1

    statement = tree.first
      .fetch('RawStmt')
      .fetch('stmt')

    # raise 'dunno how to handle more than 1 statement' if statement.keys.length > 1

    manager_from_statement statement
  end

  Contract String => ArrayOf[StrictHash[{ 'RawStmt' => {} }]]
  def self.parse_sql(sql)
    a = PgQuery.parse(sql).tree
    puts a
    # binding.pry
    a
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
    table = ast.fetch('fromClause')
    raise 'dunno how to handle multiple tables' if table.length > 1

    table = table.first

    table = Arel::Table.new(table.fetch('RangeVar').fetch('relname'))

    Arel::SelectManager.new table
  end
end
