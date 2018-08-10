module InScope
  VERSION = "0.1.0"

  def in_scope?(relation)
    values = relation.values
    bind_params = relation.values[:bind]

    relation.values[:where].each_with_index.all? do |where_node, index|
      if where_node.respond_to?(:operator) && where_node.operator == :==
        attribute = where_node.left
        attribute_name = attribute.name

        expected_value = if bind_params
          bind_params[index].last
        else
          where_node.right
        end

        self.public_send(attribute_name) == expected_value
      else
        raise "#{where_node.class} is an unsupported operation"
      end
    end
  end
end
