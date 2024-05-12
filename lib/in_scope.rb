module InScope
  VERSION = "0.1.0"

  class Evaluator
    def initialize(relation, instance)
      @relation = relation
      @instance = instance

      @instances_by_table = { instance.class.table_name => instance }
      relation.values[:joins]&.each do |join_name|
        object = instance.public_send(join_name)
        @instances_by_table[object.class.table_name] = object
      end
    end

    def eval
      cores = @relation.arel.ast.cores
      if cores.length > 1
        raise "More than one core"
      end
      root = cores.first
      eval_node(root)
    end

    private

    def eval_node(node)
      case node
      in Arel::Nodes::SelectCore
        node.wheres.all? { |node| eval_node(node) }
      in Arel::Nodes::And
        node.children.all? { |child| eval_node(child) }
      in Arel::Nodes::Or
        eval_node(node.left) || eval_node(node.right)
      in Arel::Nodes::Equality
        attribute = node.left
        attribute_name = attribute.name

        table_name = attribute.relation.name
        instance = @instances_by_table[table_name]

        if !instance
          raise "Missing join for #{table_name}"
        end

        expected_value = node.right.value

        instance.public_send(attribute_name) == expected_value
      in Arel::Nodes::Grouping
        eval_node(node.expr)
      else
        raise "#{node.class} is an unsupported operation"
      end
    end
  end

  def in_scope?(relation)
    Evaluator.new(relation, self).eval
  end
end
