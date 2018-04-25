class ThriftRack
  class FormatCheck
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      return Rack::Response.new(["Not Valid Thrift Request"], 400, {'Content-Type' => 'text/plain'}) unless req.post? && req.env["CONTENT_TYPE"] == THRIFT_HEADER
      @app.call(env)
    end
  end
end
