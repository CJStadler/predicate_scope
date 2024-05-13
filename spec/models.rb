class User < ActiveRecord::Base
  include InScope

  belongs_to :organization

  predicate_scope :adult, -> { where(age: 18..) }
  predicate_scope :in_category, ->(category) { where(organizations: { category: category }) }
end

class Organization < ActiveRecord::Base
  include InScope

  has_many :users

  predicate_scope :uncategorized, -> { where(category: nil) }
end
