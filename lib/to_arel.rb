require 'to_arel/version'
require 'arel'
require 'pg_query'

def symbolize_keys(hash)
  Hash[hash.map{|k, v| [k.to_sym, v]}]
end

#:nodoc:
module ToArel
  class UnboundColumnReference < ::Arel::Nodes::SqlLiteral; end

  class Visitor
    def accept(object)
      visit *klass_and_attributes(object)
    end

    private

    def visit(klass, attributes)
      dispatch_method = "visit_#{klass}"
      send dispatch_method, klass, attributes
    end

    def klass_and_attributes(object)
      [object.keys.first, object.values.first]
    end

    private

    def visit_String(klass, attributes)
      attributes['str']
    end

    def visit_ColumnRef(klass, attributes)
      UnboundColumnReference.new(
        attributes['fields'].map do |field|
          visit *klass_and_attributes(field)
        end.join('.') # TODO: Join . might be a poor assumption
      )
    end

    def visit_ResTarget(klass, attributes)
      visit *klass_and_attributes(attributes['val'])
    end

    def visit_RangeVar(klass, attributes)
      # TODO: I'm not sure if RangeVar should already create a Table
      Arel::Table.new attributes['relname']
    end

    def visit_SelectStmt(klass, attributes)
      froms = if (from_clauses = attributes['fromClause'])
        from_clauses.map { |from_clause| visit *klass_and_attributes(from_clause) }
      end

      targets = if (target_list = attributes['targetList'])
        target_list.map { |target| visit *klass_and_attributes(target) }
      end

      select_manager = Arel::SelectManager.new(froms.first) # TODO: multi-from is goneraz
      select_manager.projections = targets
      select_manager
    end

    def visit_RawStmt(klass, attributes)
      if (stmt = attributes['stmt'])
        visit *klass_and_attributes(stmt)
      end
    end
  end

  class Error < StandardError; end
  class MultiTableError < Error; end

  def self.parse(sql)
    tree = PgQuery.parse(sql).tree

    Visitor.new.accept(tree.first) # DUNNO Y .first
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
