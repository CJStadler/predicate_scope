class User < ActiveRecord::Base
  include InScope

  belongs_to :organization
end

class Organization < ActiveRecord::Base
  has_many :users
end
