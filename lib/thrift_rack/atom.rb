require 'redis'
class ThriftRack
  class Atom
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      if ThriftRack::Atom.redis.set("thrift_request:#{req.env["HTTP_X_RPC_ID"]}", true, nx: true, ex: 600)
        @app.call(env)
      else
        [409, {}, ["RPC Request Processed"]]
      end
    end

    class << self
      attr_accessor :redis

      def redis
        @redis ||= Redis.new
      end
    end
  end
end
