class User < ActiveRecord::Base
  include PredicateScope

  belongs_to :organization

  predicate_scope :adult, -> { where(age: 18..) }
  predicate_scope :older_than, ->(age) { where(age: age..) }
end

class Organization < ActiveRecord::Base
  include PredicateScope

  has_many :users

  predicate_scope :uncategorized, -> { where(category: nil) }
end
