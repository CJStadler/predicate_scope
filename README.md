# InScope

## Installation

Add this line to your application's Gemfile:

```rb
gem 'in_scope'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install in_scope

## Usage

Include the `InScope` module in your model:
```rb
class User < ActiveRecord::Base
  include InScope
end
```
This adds the `in_scope?` instance method. Pass it an ActiveRecord relation and
it will check whether the instance meets the conditions of the query. For
example,
```rb
an_instance.in_scope?(User.where(active: true, name: 'Foo'))
```
checks
```rb
an_instance.active && an_instance.name == 'Foo'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CJStadler/in_scope.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
