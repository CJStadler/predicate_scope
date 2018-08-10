RSpec.describe InScope do
  it "has a version number" do
    expect(InScope::VERSION).to eq('0.1.0')
  end

  describe '#in_scope?' do
    subject { user.in_scope?(relation) }

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
end
