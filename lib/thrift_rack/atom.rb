require 'redis'
class ThriftRack
  class Atom
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      rpc_id = req.env["HTTP_X_RPC_ID"]
      if rpc_id
        start_time = Time.now
        valid = ThriftRack::Atom.redis.set("thrift_request:#{rpc_id}", true, nx: true, ex: 900)
        if valid
          env["ATOM_DURATION"] = ((Time.now - start_time) * 1000).round(4)
          @app.call(env)
        else
          [409, {}, ["RPC Request Processed"]]
        end
      else
        @app.call(env)
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
