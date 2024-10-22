RSpec.describe PredicateScope do
  it "has a version number" do
    expect(PredicateScope::VERSION).to eq('0.1.0')
  end

  describe '#satisfies_conditions_of?' do
    subject { user.satisfies_conditions_of?(relation) }

    shared_examples "satisfied" do
      it "returns true" do
        expect(subject).to eq(true)
        # Confirm that the object does satisfy the conditions by querying.
        expect(relation).to include(user)
      end
    end

    shared_examples "not satisfied" do
      it "returns false" do
        expect(subject).to eq(false)
        # Confirm that the object does not satisfy the conditions by querying.
        expect(relation).not_to include(user)
      end
    end

    let!(:organization) { Organization.create(category: 'Company') }
    let!(:user) do
      User.create(active: true, name: 'Foo', age: 72, organization: organization)
    end

    # TODO: join through has_many
    context 'when there is a join through a belongs_to relation' do
      let(:user_relation) do
        User.joins(:organization).
          where(active: user.active, name: user.name, age: user.age)
      end

      context 'when the associated instance satisfies the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: organization.category })
        end

        include_examples "satisfied"
      end

      context 'when the associated instance does not satisfy the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: 'Government' })
        end

        include_examples "not satisfied"
      end
    end

    context "when there is an includes through a belongs_to relation" do
      let(:user_relation) do
        User.includes(:organization).
          where(active: user.active, name: user.name, age: user.age)
      end

      context 'when the associated instance satisfies the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: organization.category })
        end

        include_examples "satisfied"
      end

      context 'when the associated instance does not satisfy the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: 'Government' })
        end

        include_examples "not satisfied"
      end
    end

    context "when there is an or condition" do
      context "when its left side is satisfied" do
        let(:relation) do
          User.
            joins(:organization).
            where(organizations: { category: organization.category }).
            or(User.where(age: user.age + 1))
        end

        include_examples "satisfied"
      end

      context "when its right side is satisfied" do
        let(:relation) do
          User.
            joins(:organization).
            where(organizations: { category: organization.category + "Not" }).
            or(User.where(age: user.age))
        end

        include_examples "satisfied"
      end

      context "when neither side is satisfied" do
        let(:relation) do
          User.
            joins(:organization).
            where(organizations: { category: organization.category + "Not" }).
            or(User.where(age: user.age + 1))
        end

        include_examples "not satisfied"
      end
    end

    context "when there is a not condition" do
      # Using two conditions generates a `Not` node, instead of `NotEquals`.
      let(:relation) { User.where.not(active: active, age: user.age) }

      context "when the sub-condition is satisfied" do
        let(:active) { true }
        include_examples "not satisfied"
      end

      context "when the sub-condition is not satisfied" do
        let(:active) { false }
        include_examples "satisfied"
      end
    end

    context "when there is an in condition" do
      let(:relation) { User.where(age: ages) }

      context "when the list is empty" do
        let(:ages) { [] }
        include_examples "not satisfied"
      end

      context "when the list is empty" do
        let(:ages) { [] }
        include_examples "not satisfied"
      end

      context "when one of the elements is equal" do
        let(:ages) { [user.age - 1, user.age, user.age + 1] }
        include_examples "satisfied"
      end

      context "when none of the elements are equal" do
        let(:ages) { [user.age - 1, user.age + 1] }
        include_examples "not satisfied"
      end
    end

    context "when there a comparison" do
      let(:actual_age) { 18 }
      let(:younger_user) { User.create(age: actual_age - 1) }
      let(:equal_user) { User.create(age: actual_age) }
      let(:older_user) { User.create(age: actual_age + 1) }

      context "equality" do
        let(:relation) { User.where(age: actual_age) }

        it "obeys the operator" do
          expect(younger_user.satisfies_conditions_of?(relation)).to eq(false)
          expect(equal_user.satisfies_conditions_of?(relation)).to eq(true)
          expect(older_user.satisfies_conditions_of?(relation)).to eq(false)
        end
      end

      context "not equal" do
        let(:relation) { User.where.not(age: actual_age) }

        it "obeys the operator" do
          expect(younger_user.satisfies_conditions_of?(relation)).to eq(true)
          expect(equal_user.satisfies_conditions_of?(relation)).to eq(false)
          expect(older_user.satisfies_conditions_of?(relation)).to eq(true)
        end
      end

      context "greater than" do
        let(:relation) { User.where(User.arel_table[:age].gt(18)) }

        it "obeys the operator" do
          expect(younger_user.satisfies_conditions_of?(relation)).to eq(false)
          expect(equal_user.satisfies_conditions_of?(relation)).to eq(false)
          expect(older_user.satisfies_conditions_of?(relation)).to eq(true)
        end
      end

      context "less than" do
        let(:relation) { User.where(age: ...actual_age) }

        it "obeys the operator" do
          expect(younger_user.satisfies_conditions_of?(relation)).to eq(true)
          expect(equal_user.satisfies_conditions_of?(relation)).to eq(false)
          expect(older_user.satisfies_conditions_of?(relation)).to eq(false)
        end
      end

      context "greater than or equal" do
        let(:relation) { User.where(age: actual_age..) }

        it "obeys the operator" do
          expect(younger_user.satisfies_conditions_of?(relation)).to eq(false)
          expect(equal_user.satisfies_conditions_of?(relation)).to eq(true)
          expect(older_user.satisfies_conditions_of?(relation)).to eq(true)
        end
      end

      context "less than or equal" do
        let(:relation) { User.where(age: ..actual_age) }

        it "obeys the operator" do
          expect(younger_user.satisfies_conditions_of?(relation)).to eq(true)
          expect(equal_user.satisfies_conditions_of?(relation)).to eq(true)
          expect(older_user.satisfies_conditions_of?(relation)).to eq(false)
        end
      end
    end

    context "when there is an unsupported operation" do
      let(:relation) { User.where("age = 45") }
      it "raises UnsupportedOperation" do
        expect { subject }.to raise_error(
          PredicateScope::Errors::UnsupportedOperation,
          "Operation node type Arel::Nodes::SqlLiteral is not yet supported."
        )
      end
    end

    context "when a table definition is missing" do
      let(:relation) { User.where(organizations: { category: "cat"}) }
      it "raises MissingTableDefinition" do
        expect { subject }.to raise_error(
          PredicateScope::Errors::MissingAssociation,
          "Missing association for table \"organizations\". You probably need to join it."
        )
      end
    end
  end

  describe ".predicate_scope" do
    let!(:adult_user) { User.create(age: 20) }
    let!(:child_user) { User.create(age: 17) }

    context "when the lambda has no parameters" do
      it "generates a scope using the given conditions" do
        relation = User.adult
        expect(relation).to include(adult_user)
        expect(relation).not_to include(child_user)
      end

      it "generates a predicate method using the given conditions" do
        expect(adult_user.adult?).to eq(true)
        expect(child_user.adult?).to eq(false)
      end
    end

    context "when the lambda has parameters" do
      it "generates a scope that using the given conditions that takes the parameters" do
        relation = User.older_than(18)
        expect(relation).to include(adult_user)
        expect(relation).not_to include(child_user)
      end

      it "generates a predicate method using the given conditions that takes the parameters" do
        expect(adult_user.older_than?(18)).to eq(true)
        expect(child_user.older_than?(18)).to eq(false)
      end
    end
  end

  describe ".predicate" do
    let(:admin_user) { User.create(active: true, role: "admin") }
    let(:guest_user) { User.create(active: true, role: "guest") }

    it "generates a predicate instance method based on the conditions" do
      expect(admin_user.admin?).to eq(true)
      expect(guest_user.admin?).to eq(false)
    end

    it "generates a scope based on the conditions" do
      expect(User.admin).to include(admin_user)
      expect(User.admin).not_to include(guest_user)
    end
  end
end
