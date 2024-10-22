module PredicateScope
  module Expressions
    class Expression
      def self.deserialize(serialized)
        case serialized
        in {_op: :and, _args:}
          And.new(_args.map { |v| Expression.deserialize(v) })
        in {_op: :or, _args:}
          Or.new(_args.map { |v| Expression.deserialize(v) })
        in {_op: :not, _arg:}
          Not.new(Expression.deserialize(_arg))
        in {_op:}
          raise "invalid"
        in Hash
          Attributes.new(serialized.transform_values { |v| Expression.deserialize(v) })
        in Array
          Or.new(serialized.map{ |v| Expression.deserialize(v) })
        else
          Value.new(serialized)
        end
      end
    end

    class Attributes < Expression
      def initialize(attributes_map)
        @attributes_map = attributes_map
      end

      def serialize
        @attributes_map.transform_values(&:serialize)
      end

      def eval(object)
        @attributes_map.all? do |name, value|
          actual = object.public_send(name)
          value.eval(actual)
        end
      end
    end

    class And < Expression
      def initialize(operands)
        @operands = operands
      end

      def serialize
        {
          _op: :and,
          _args: @operands.map(&:serialize)
        }
      end

      def eval(object)
        @operands.all? { |op| op.eval(object) }
      end
    end

    class Or < Expression
      def initialize(operands)
        @operands = operands
      end

      def serialize
        {
          _op: :or,
          _args: @operands.map(&:serialize)
        }
      end

      def eval(object)
        @operands.any? { |op| op.eval(object) }
      end
    end

    class Not < Expression
      def initialize(sub_expression)
        @sub_expression = sub_expression
      end

      def serialize
        {
          _op: :not,
          _arg: @sub_expression.serialize
        }
      end

      def eval(object)
        !@sub_expression.eval(object)
      end
    end

    # TODO: rename to Equality?
    class Value < Expression
      def initialize(value)
        @value = value
      end

      def serialize
        @value
      end

      def eval(object)
        object == @value
      end
    end
  end
end
