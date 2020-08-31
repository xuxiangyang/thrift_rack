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
        valid = ThriftRack.redis.set("thrift_rack:atom:#{rpc_id}", true, nx: true, ex: 180)
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
      # compatibility with old version
      def redis=(r)
        ThriftRack.redis = r
      end
    end
  end
end
