# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grailbird_updater/version'

Gem::Specification.new do |gem|
  gem.name          = "grailbird_updater"
  gem.version       = GrailbirdUpdater::VERSION
  gem.authors       = ["Dannel Jurado"]
  gem.email         = ["dannelj@gmail.com"]
  gem.description   = %q{Twitter now allows you to download your tweets. This tool lets you keep that archive up to date.}
  gem.summary       = %q{A way to keep an updated archive of Twitter tweets.}
  gem.homepage      = "https://github.com/DeMarko/grailbird_updater"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
