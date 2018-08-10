module InScope
  VERSION = "0.1.0"

  def in_scope?(relation)
    objects_by_table = { self.class.table_name => self }
    relation.values[:joins]&.each do |join_name|
      object = self.public_send(join_name)
      objects_by_table[object.class.table_name] = object
    end

    bind_params = relation.values[:bind]

    relation.values[:where].each_with_index.all? do |where_node, index|
      if where_node.respond_to?(:operator) && where_node.operator == :==
        attribute = where_node.left
        attribute_name = attribute.name

        table_name = attribute.relation.name
        object = objects_by_table[table_name]

        expected_value = if bind_params
          bind_params[index].last
        else
          where_node.right
        end

        object.public_send(attribute_name) == expected_value
      else
        raise "#{where_node.class} is an unsupported operation"
      end
    end
  end
end
