require 'pbt'

RSpec.describe PredicateScope do
  describe '#satisfies_conditions_of? with pbt' do
    it "matches include?" do
      Pbt.assert(num_runs: 1000, verbose: true) do
        Pbt.property(Pbt.alphanumeric_string(max: 2), Pbt.boolean, Pbt.alphanumeric_string(max: 2), Pbt.integer, Pbt.alphanumeric_string(max: 2), Pbt.boolean, Pbt.alphanumeric_string(max: 2), Pbt.integer) do |category, active, name, age, q_category, q_active, q_name, q_age|
          organization = Organization.create(category: category)
          user = User.create(active: active, name: name, age: age, organization: organization)

          base = User.joins(:organization)
          relations = [
            base.where(active: q_active),
            base.where(name: q_name),
            base.where(age: ..q_age),
            base.where(age: q_age..),
            base.where(organizations: { category: q_category }),
            base.where(active: q_active).or(User.where(name: q_name).where.not(age: q_age)),
            base.where(active: q_active, name: q_name, age: ..q_age, organizations: { category: q_category })
          ]
          relations.each.with_index do |relation, i|
            actual = user.satisfies_conditions_of?(relation)
            expected = relation.include?(user)
            if actual != expected
              raise "#satisfies_conditions_of returned #{actual} but #include? returned #{expected}"
            # elsif actual
            #   print ".#{i}"
            end
          end
        end
      end
    end
  end
end
