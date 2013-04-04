# -*- encoding: utf-8 -*-
require File.expand_path('../lib/eager_beaver/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kevin Burleigh"]
  gem.email         = ["klb@kindlinglabs.com"]
  gem.description   = %q{Facilitates method_missing, respond_to_missing?, and method-generation activities}
  gem.summary       = %q{Facilitates method_missing, respond_to_missing?, and method-generation activities
                         by providing a simple interface for adding method generators.  All related
                         activities, such as registering with #method_missing and #respond_to_missing?
                         are handled automatically.  Facilitates method name pattern-specific method
                         generation as well.  Generated methods are added to the missing method receiver.}
  gem.homepage      = "http://github.com/kevinburleigh75/eager_beaver"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "eager_beaver"
  gem.require_paths = ["lib"]
  gem.version       = EagerBeaver::VERSION
end
