class ThriftRack
  class FormatCheck
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      return 400, {'Content-Type' => 'text/plain'}, ["Not Valid Thrift Request"] unless req.post? && req.env["CONTENT_TYPE"] == THRIFT_HEADER
      @app.call(env)
    end
  end
end
