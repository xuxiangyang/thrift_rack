class ThriftRack
  class Sentry
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      Raven.extra_context(request_id: req.env["HTTP_X_REQUEST_ID"], rpc_id: req.env["HTTP_X_RPC_ID"], from: req.env["HTTP_X_FROM"])
      @app.call(env)
    end
  end
end
