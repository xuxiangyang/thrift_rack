class ThriftRack
  class ServerMetric
    def initialize(app)
      @app = app
    end

    def call(env)
      request_at = env['LAUNCH_AT'] || Time.now
      status, headers, body = @app.call(env)
      headers["x-server-process-duration"] = ((Time.now - request_at) * 1000).to_s
      headers["x-server-id"] = self.class.server_id
      headers["x-server-private-ip"] = self.class.server_private_ip
      [status, headers, body]
    end

    class << self
      attr_writer :server_id, :server_private_ip

      def server_id
        @server_id || "unkonwn"
      end

      def server_private_ip
        @server_private_ip || "0.0.0.0"
      end
    end
  end
end
