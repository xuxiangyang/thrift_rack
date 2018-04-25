class ThriftRack
  class Ping
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      return Rack::Response.new(["PONG"], 200, {'Content-Type' => 'text/plain'}) if req.path == "/ping"
      @app.call(env)
    end
  end
end
