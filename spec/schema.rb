ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.boolean :active
    t.string :role
    t.integer :age
    t.string :name
    t.integer :organization_id
  end

  create_table :organizations, :force => true do |t|
    t.string :category
  end
end
