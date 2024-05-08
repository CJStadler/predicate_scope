module InScope
  VERSION = "0.1.0"

  def in_scope?(relation)
    cores = relation.arel.ast.cores
    if cores.length > 1
      raise "More than one core"
    end
    root = cores.first

    objects_by_table = { self.class.table_name => self }
    relation.values[:joins]&.each do |join_name|
      object = self.public_send(join_name)
      objects_by_table[object.class.table_name] = object
    end

    # TODO: move out of method?
    def eval_node(node, objects_by_table)
      case node
      in Arel::Nodes::And
        node.children.all? { |child| eval_node(child, objects_by_table) }
      in Arel::Nodes::Or
        eval_node(node.left, objects_by_table) || eval_node(node.right, objects_by_table)
      in Arel::Nodes::Equality
        attribute = node.left
        attribute_name = attribute.name

        table_name = attribute.relation.name
        object = objects_by_table[table_name]

        if !object
          raise "Missing join for #{table_name}"
        end

        expected_value = node.right.value

        object.public_send(attribute_name) == expected_value
      in Arel::Nodes::Grouping
        eval_node(node.expr, objects_by_table)
      else
        raise "#{node.class} is an unsupported operation"
      end
    end

    root.wheres.each_with_index.all? do |node, index|
      eval_node(node, objects_by_table)
    end
  end
end
