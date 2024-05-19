module InScope
  VERSION = "0.1.0"

  module ClassMethods
    def predicate_scope(name, body, ...)
      # Add the scope to the class.
      scope(name, body, ...)

      # Define the predicate instance method.
      predicate_name = :"#{name}?"
      define_method(predicate_name) do |*args|
        relation = body.call(*args)
        in_scope?(relation)
      end
    end
  end

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
      in Arel::Nodes::Not
        !eval_node(node.expr)
      in Arel::Nodes::And
        node.children.all? { |child| eval_node(child) }
      in Arel::Nodes::Or
        eval_node(node.left) || eval_node(node.right)
      # This is used with `or` but I don't know what it represents.
      in Arel::Nodes::Grouping
        eval_node(node.expr)
      in Arel::Nodes::In
        attribute_value = eval_attribute(node.left)
        if node.right.is_a?(Enumerable)
          node.right.any? { |value| value == attribute_value }
        else
          raise "#{node.class} not supported with this argument"
        end
      in Arel::Nodes::HomogeneousIn
        attribute_value = eval_attribute(node.attribute)
        node.values.any? { |value| value == attribute_value }
      in Arel::Nodes::Equality
        eval_comparison(node, :==)
      in Arel::Nodes::NotEqual
        eval_comparison(node, :!=)
      in Arel::Nodes::GreaterThan
        eval_comparison(node, :>)
      in Arel::Nodes::LessThan
        eval_comparison(node, :<)
      in Arel::Nodes::GreaterThanOrEqual
        eval_comparison(node, :>=)
      in Arel::Nodes::LessThanOrEqual
        eval_comparison(node, :<=)
      else
        raise "#{node.class} is an unsupported operation node"
      end
    end

    def eval_comparison(node, operator)
      eval_attribute(node.left).public_send(operator, eval_attribute(node.right))
    end

    def eval_attribute(attribute)
      case attribute
      in Arel::Attributes::Attribute
        table_name = attribute.relation.name
        instance = @instances_by_table[table_name]

        if instance
          instance.public_send(attribute.name)
        else
          raise "Missing join for #{table_name}"
        end
      in ActiveRecord::Relation::QueryAttribute | Arel::Nodes::Casted
        attribute.value
      else
        raise "#{attribute.class} is an unsupported attribute type"
      end
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def in_scope?(relation)
    Evaluator.new(relation, self).eval
  end
end
