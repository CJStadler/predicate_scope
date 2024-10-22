# predicate_scope

Have you ever written code like this?

```rb
class User < ActiveRecord::Base
  scope :active, -> { where(deleted: false, state: "confirmed") }

  def active?
    !deleted && state == "confirmed"
  end
end
```

And noticed that the definition of an "active" user is duplicated? What if the
definition changes, and you forget to update both places?

With `predicate_scope` you can write it once:

```rb
class User < ActiveRecord::Base
  include PredicateScope

  predicate_scope :active, -> { where(deleted: false, state: "confirmed") }
end
```

This defines two methods:
- A `User.active` scope, as if you had used `scope` like normal.
- A predicate instance method `User#active?`, which behaves just like the
hand-written version of `active?` in the original example:

```rb
user = User.new(deleted: false, state: "confirmed")
user.active? # true
user.state = "unconfirmed"
user.active? # false
```

The predicate method checks the conditions of the scope against the instance _in
memory_, without querying the database. Again, just like the hand-written `active?`.

## Implementation

In addition to `predicate_scope`, this gem also defines a instance method
`#satisfies_conditions_of?`. This takes an `ActiveRecord::Relation` and returns
whether the instance it is called on satisfies its conditions. The predicate
methods defined by `predicate_scope` call `satisfies_conditions_of?` with the
relation from the scope. So in the above example `user.active?` is implemented
as `user.satisfies_conditions_of?(User.active)`.

`satisfies_conditions_of? ` extracts the `Arel` abstract syntax tree (AST)
from the given `ActiveRecord::Relation` and interprets its conditions as Ruby
predicates. These predicates are evaluated against the instance.

## Limitations

Not all `Arel` operations are implemented. If you define
a `predicate_scope` that uses an unsupported operation
`PredicateScope::Errors::UnsupportedOperation` will be raised when the predicate
method is called. PRs to implement additional operations are appreciated!

## Installation

Add this line to your application's Gemfile:

```rb
gem 'predicate_scope'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install predicate_scope

In any models where you want to use `predicate_scope` add

```rb
include PredicateScope
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/CJStadler/predicate_scope.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Notes

```rb
{organization: {name: "foo"}}
self.organization.name == "foo"
joins(:organization).where({organization: {name: "foo"}})
```

```rb
{orders_count: {_op: :not, _arg: [1, 3, 5]}}
{orders_count: P::Not([1, 3, 5])}

![1, 3, 5].any? { |x| x == self.orders_count }
![1, 3, 5].include?(self.orders_count)
Customer.where.not(orders_count: [1, 3, 5])
SELECT * FROM customers WHERE (customers.orders_count NOT IN (1,3,5))
[1, 3, 5].include?(self.orders_count)
```

```rb
[{last_name: "Smith"}, {orders_count: [1, 3, 5]}]
{_op: :or, _args: [{last_name: "Smith"}, {orders_count: [1, 3, 5]}]}
P::Or({last_name: "Smith"}, {orders_count: [1, 3, 5]})

self.last_name == "Smith" || [1, 3, 5].any? { |x| x == self.orders_count }
Customer.where(last_name: 'Smith').or(Customer.where(orders_count: [1, 3, 5]))
SELECT * FROM customers WHERE (customers.last_name = 'Smith' OR customers.orders_count IN (1,3,5)
```

```rb
{id: {_op: :and, _args: [[1, 2], [2, 3]]}}
{id: P::And([1, 2], [2, 3])}

(self.id == 1 || self.id == 2) && (self.id == 2 || self.id == 3)
Customer.where(id: [1, 2]).and(Customer.where(id: [2, 3]))
SELECT * FROM customers WHERE (customers.id IN (1, 2) AND customers.id IN (2, 3))
```
