
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "predicate_scope"

Gem::Specification.new do |spec|
  spec.name          = "predicate_scope"
  spec.version       = PredicateScope::VERSION
  spec.authors       = ["Chris Stadler"]
  spec.email         = ["chrisstadler@gmail.com"]

  spec.summary       = 'Check whether an ActiveRecord instance satisfies the conditions of a relation, in memory'
  spec.homepage      = "https://github.com/CJStadler/predicate_scope"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_development_dependency "bundler", "~> 2.5"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "activerecord", "~> 7.1"
  spec.add_development_dependency "sqlite3", "~> 1.4" # activerecord seems to require this version.
  spec.add_development_dependency "pbt"
  spec.add_development_dependency "pry-byebug"
end
