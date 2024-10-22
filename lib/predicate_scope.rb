require "predicate_scope/expressions"

module PredicateScope
  VERSION = "0.1.0"

  module Errors
    class UnsupportedOperation < StandardError
      def initialize(node)
        super("Operation node type #{node.class} is not yet supported.")
      end
    end

    class UnsupportedAttribute < StandardError
      def initialize(attribute)
        super("Attribute type #{attribute.class} is not yet supported.")
      end
    end

    class UnsupportedInOperand < StandardError
      def initialize(operand)
        super("In operations with operand type #{operand.class} are not yet supported.")
      end
    end

    class MissingAssociation < StandardError
      def initialize(table)
        super("Missing association for table \"#{table}\". You probably need to join it.")
      end
    end

    class MultipleCores < StandardError
      def initialize
        super("More than one core is not yet supported.")
      end
    end
  end

  module ClassMethods
    def predicate(name, conditions)
      conditions_expression = Expressions::Expression.deserialize(conditions)

      # Add the scope to the class.
      relation_proc = ->() do
        where(conditions)
      end
      scope(name, relation_proc)

      # Define the predicate instance method.
      predicate_name = :"#{name}?"
      define_method(predicate_name) do |*predicate_args|
        if !predicate_args.empty?
          raise "TODO: arg handling"
        end

        conditions_expression.eval(self)
      end
    end

    def predicate_scope(scope_name, relation_proc, ...)
      # Add the scope to the class.
      scope(scope_name, relation_proc, ...)

      # Define the predicate instance method.
      predicate_name = :"#{scope_name}?"
      define_method(predicate_name) do |*predicate_args|
        relation = relation_proc.call(*predicate_args)
        satisfies_conditions_of?(relation)
      end
    end
  end

  class Evaluator
    def initialize(conditions, instance)
      @conditions = conditions
      @instance = instance
    end

    def eval
      case @conditions
      in Array
        raise "TODO"
      in Hash
        @conditions.all? do |k, v|
          @instance.public_send(k) == v
        end
      else
        raise "TODO"
      end
    end
  end

  class RelationEvaluator
    def initialize(relation, instance)
      @relation = relation
      @instance = instance

      @instances_by_table = { instance.class.table_name => instance }
      associations = relation.values[:joins].to_a.chain(relation.values[:includes].to_a)
      associations.each do |association_name|
        object = instance.public_send(association_name)
        @instances_by_table[object.class.table_name] = object
      end
    end

    def eval
      cores = @relation.arel.ast.cores
      if cores.length > 1
        raise Errors::MultipleCores.new
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
          raise Errors::UnsupportedInOperand.new(node.right)
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
        # TODO: Between
        raise Errors::UnsupportedOperation.new(node)
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
          raise Errors::MissingAssociation.new(table_name)
        end
      in ActiveRecord::Relation::QueryAttribute | Arel::Nodes::Casted
        attribute.value
      else
        raise Errors::UnsupportedAttribute.new(attribute)
      end
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def satisfies_conditions_of?(relation)
    RelationEvaluator.new(relation, self).eval
  end
end
