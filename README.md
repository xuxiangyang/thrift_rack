# ThriftRack

ThriftRack implements [thrift]([https://thrift.apache.org](https://thrift.apache.org/)) `Compact Protocol + HTTP Transport ` with rack, and makes it easy to write a server with convention.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'thrift_rack'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install thrift_rack

## Usage

### Server

Assume  you use rails only with `activemodel`、`activerecord`、`activesupport`. Because ThriftRack act as controller and view, you do not need `actionview` and `actionpack`

You cloud new a rails app use this command

```bash
rails new demo --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-record --skip-active-storage --skip-action-cable --skip-sprockets --skip-javascript --skip-turbolinks --skip-test --skip-system-test --skip-bootsnap --api --skip-webpack-install
```

Suppose you has a thrift named `math.thrift` to add two number:

```thrift
# math.thrift
namespace rb thrift.math # namesapce should same with filename

service MathService { # Math is capitalized from Math
  int add(1: int i, 2: int j)
}
```

then you should implement this thrift in `math_server.rb`

```ruby
class MathServer < ThriftRack::Server
  def add(i, j)
    i + j
  end
end
```

Then change the `config.ru`

```
require_relative 'config/environment'
app = ThriftRack.app(ThriftRack::Server.children)
run app
```

Another config under initializers

```ruby
#initializers/thrift.rb
Dir["#{Rails.root}/lib/thrift/**/*.rb"].each { |file| require file } # support generate thrift files under lib/thrift
Dir["#{Rails.root}/app/servers/*.rb"].each { |file| require file } # support servers under app/servers

ThriftRack.redis = Redis.new
ThriftRack::Logger.tag = { key: value} # tag to logs

at_exit do
  ThriftRack::Logger.logger.close
end
```

Then run this bash

```
rackup
```

what happend?

* We implement the math.thrift with `POST` method at `/math` path
* A Server seems like a controller, except that you do not need to write routes.
* We replace the default rails rack entrance, but it still a rack server. **You could use puma to web server, and enjoy puma's advantage**.
* Client will auto retry with network jitter, Atom ensure each request at most processed once.
* `/ping` should be use to health check, all request to `/ping` will not be log
* `ThriftRack::Logger` log each rpc request with json format. You could use ELK to analyze each request

### Client

client cloud write like this

```ruby
class Math
  attr_accessor :client
  def initialize(request_id = "no-request-id") # web should has one request_id
    @client = ThriftRack::Client.new("http://127.0.0.1:300/math", ThriftClientClass, request_id)
  end

  def add(i, j)
    self.client.add(i, j)
  end
end
```

Another config under initializers

```ruby
#initializers/thrift.rb
Dir["#{Rails.root}/lib/thrift/**/*.rb"].each { |file| require file }

ThriftRack::Client.config Rails.application.class.parent.name.underscore
```

what happend?

* Client will auto generate a `rpc_id` to tracer rpc request
* Client will add app_name to header
* Client use HTTP 1.1, wich persistent tcp connection with multi http requests
* Client has a connection pool, network error will auto retry
* Client will log each rpc process time

#### Furthermore

you chould write a supperclass like under, other client inherit superclass

1. you could write a around_action to set request

   ```ruby
   class ApplicationController < ActionController::API
     around_action :set_thread_local_request

     private

     def set_thread_local_request
       Thread.current["request"] = request
       yield
     ensure
       Thread.current["request"] = nil
     end
   end
   ```

2. write a superclass

   ```ruby
   class ClientBase
     def initialize(req = nil)
       if req
         @request_id = req.request_id
       end
     end

     def request_id
       @request_id ||= Thread.current["request"] ? Thread.current["request"].request_id : "no-request-id"
     end

     def client
       ThriftRack::Client.new("http:127.0.0.1:3000/#{_namespace.underscore}", _client_class, request_id)
     end

     def respond_to_missing?(method, include_private = false)
       self.client.respond_to?(method)
     end

     def method_missing(method, *args)
       return super unless self.client.respond_to?(method)
       self.class_eval do
         define_method method.to_sym do |*params|
           self.client.public_send(method, *params)
         end
       end
       self.public_send(method, *args)
     end

     private

     def _namespace
       @namespace ||= self.class.name
     end

     def _client_class
       "Thrift::#{_namespace}::#{_namespace}Service::Client".constantize
     end

     class << self
       def default
         self.new
       end

       def respond_to_missing?(method, include_private = false)
         self.default.respond_to?(method)
       end

       def method_missing(method, *params)
         return super unless self.default.respond_to?(method)
         define_singleton_method method.to_sym do |*args|
           self.default.public_send(method, *args)
         end
         self.public_send(method, *params)
       end
     end
   end
   ```

3. inherit super class

   ```ruby
   class Math < ClientBase
     def add(i, j)
       self.client.add(i, j)
     end
   end
   ```

4. use

   ```
   Math.add(1, 2) # will auto assign request_id is with request
   ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/thrift_rack. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ThriftRack project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/thrift_rack/blob/master/CODE_OF_CONDUCT.md).
