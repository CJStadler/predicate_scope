RSpec.describe InScope do
  it "has a version number" do
    expect(InScope::VERSION).to eq('0.1.0')
  end

  # TODO: spec with SQL (should fail).
  describe '#in_scope?' do
    subject { user.in_scope?(relation) }

    let(:organization) { Organization.create(category: 'Company') }
    let(:user) do
      User.new(active: true, name: 'Foo', age: 72, organization: organization)
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

        it { is_expected.to eq(true) }
      end

      context 'when the associated instance does not satisfy the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: 'Government' })
        end

        it { is_expected.to eq(false) }
      end
    end

    context "when there is an includes through a belogns_to relation" do
      let(:user_relation) do
        User.includes(:organization).
          where(active: user.active, name: user.name, age: user.age)
      end

      context 'when the associated instance satisfies the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: organization.category })
        end

        it { is_expected.to eq(true) }
      end

      context 'when the associated instance does not satisfy the conditions' do
        let(:relation) do
          user_relation.
            where(organizations: { category: 'Government' })
        end

        it { is_expected.to eq(false) }
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

        it { is_expected.to eq(true) }
      end

      context "when its right side is satisfied" do
        let(:relation) do
          User.
            joins(:organization).
            where(organizations: { category: organization.category + "Not" }).
            or(User.where(age: user.age))
        end

        it { is_expected.to eq(true) }
      end

      context "when neither side is satisfied" do
        let(:relation) do
          User.
            joins(:organization).
            where(organizations: { category: organization.category + "Not" }).
            or(User.where(age: user.age + 1))
        end

        it { is_expected.to eq(false) }
      end
    end

    context "when there is a not condition" do
      # Using two conditions generates a `Not` node, instead of `NotEquals`.
      let(:relation) { User.where.not(active: active, age: user.age) }

      context "when the sub-condition is satisifed" do
        let(:active) { true }
        it { is_expected.to eq(false) }
      end

      context "when the sub-condition is not satisifed" do
        let(:active) { false }
        it { is_expected.to eq(true) }
      end
    end

    context "when there is an in condition" do
      let(:relation) { User.where(age: ages) }

      context "when the list is empty" do
        let(:ages) { [] }
        it { is_expected.to eq(false) }
      end

      context "when the list is empty" do
        let(:ages) { [] }
        it { is_expected.to eq(false) }
      end

      context "when one of the elements is equal" do
        let(:ages) { [user.age - 1, user.age, user.age + 1] }
        it { is_expected.to eq(true) }
      end

      context "when none of the elements are equal" do
        let(:ages) { [user.age - 1, user.age + 1] }
        it { is_expected.to eq(false) }
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
          expect(younger_user.in_scope?(relation)).to eq(false)
          expect(equal_user.in_scope?(relation)).to eq(true)
          expect(older_user.in_scope?(relation)).to eq(false)
        end
      end

      context "not equal" do
        let(:relation) { User.where.not(age: actual_age) }

        it "obeys the operator" do
          expect(younger_user.in_scope?(relation)).to eq(true)
          expect(equal_user.in_scope?(relation)).to eq(false)
          expect(older_user.in_scope?(relation)).to eq(true)
        end
      end

      context "greater than" do
        let(:relation) { User.where(User.arel_table[:age].gt(18)) }

        it "obeys the operator" do
          expect(younger_user.in_scope?(relation)).to eq(false)
          expect(equal_user.in_scope?(relation)).to eq(false)
          expect(older_user.in_scope?(relation)).to eq(true)
        end
      end

      context "less than" do
        let(:relation) { User.where(age: ...actual_age) }

        it "obeys the operator" do
          expect(younger_user.in_scope?(relation)).to eq(true)
          expect(equal_user.in_scope?(relation)).to eq(false)
          expect(older_user.in_scope?(relation)).to eq(false)
        end
      end

      context "greater than or equal" do
        let(:relation) { User.where(age: actual_age..) }

        it "obeys the operator" do
          expect(younger_user.in_scope?(relation)).to eq(false)
          expect(equal_user.in_scope?(relation)).to eq(true)
          expect(older_user.in_scope?(relation)).to eq(true)
        end
      end

      context "less than or equal" do
        let(:relation) { User.where(age: ..actual_age) }

        it "obeys the operator" do
          expect(younger_user.in_scope?(relation)).to eq(true)
          expect(equal_user.in_scope?(relation)).to eq(true)
          expect(older_user.in_scope?(relation)).to eq(false)
        end
      end
    end
  end

  # TODO: add tests that `user.in_scope?(relation) == relation.includes?(user)`
  describe "#predicate_scope" do
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
end
