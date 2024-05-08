RSpec.describe InScope do
  it "has a version number" do
    expect(InScope::VERSION).to eq('0.1.0')
  end

  describe '#in_scope?' do
    subject { user.in_scope?(relation) }

    let(:organization) { Organization.create(category: 'Company') }
    let(:user) do
      User.new(active: true, name: 'Foo', age: 72, organization: organization)
    end

    context 'when there are no joins' do
      let(:user) { User.new(active: true, name: 'Foo', age: 72) }

      context 'when the instance satisfies the conditions' do
        let(:relation) do
          User.where(active: user.active, name: user.name, age: user.age)
        end

        it { is_expected.to eq(true) }
      end

      context 'when the instance does not satisfy the conditions' do
        let(:relation) do
          User.where(active: user.active, name: user.name, age: user.age + 1)
        end

        it { is_expected.to eq(false) }
      end
    end

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
  end
end
