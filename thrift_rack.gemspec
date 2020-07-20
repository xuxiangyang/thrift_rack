
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "thrift_rack/version"

Gem::Specification.new do |spec|
  spec.name          = "thrift_rack"
  spec.version       = ThriftRack::VERSION
  spec.authors       = ["xuxiangyang"]
  spec.email         = ["xxy@xuxiangyang.com"]

  spec.summary       = %q{thrift http rakc server}
  spec.description   = %q{thrift http rakc server}
  spec.homepage      = "https://github.com/xuxiangyang/thrift_rack"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 2.0.6"
  spec.add_dependency "thrift", '~> 0.10'
  spec.add_dependency 'net-http-persistent', ">= 3.0"
  spec.add_dependency 'redis', '>=3.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry", "~> 0"
end
