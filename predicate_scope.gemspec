
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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3", "~> 1.4" # activerecord seems to require this version.
  spec.add_development_dependency 'pry'
end
