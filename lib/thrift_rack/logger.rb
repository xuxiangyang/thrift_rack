require 'logger'
require 'json'
class ThriftRack
  class Logger
    def initialize(app)
      @app = app
    end

    def call(env)
      request_at = env['LAUNCH_AT'] || Time.now
      income_middleware_duration = Time.now - request_at
      req = Rack::Request.new(env)
      resp = @app.call(env)
      resp
    ensure
      duration = ((Time.now - request_at) * 1000).round(4)
      request_id = req.env["HTTP_X_REQUEST_ID"]
      if req.env["HTTP_X_FULL_TRACE"]
        full_trace = req.env["HTTP_X_FULL_TRACE"] == "true"
      else
        full_trace = request_id.hash % 8 == 0
      end
      if full_trace || duration >= 100
        ThriftRack::Logger.logger.info(
          JSON.dump(
            request_at: request_at.iso8601(6),
            request_id: request_id,
            rpc_id: req.env["HTTP_X_RPC_ID"],
            duration: duration,
            income_middleware_duration: (income_middleware_duration * 1000).round(2),
            atom_duration: env["ATOM_DURATION"],
            path: req.path,
            func: req.env["HTTP_X_RPC_FUNC"],
            from: req.env["HTTP_X_FROM"],
            full_trace: full_trace,
            tag: Logger.tag,
          ),
        )
      end
    end

    class << self
      attr_writer :tag

      def logger
        @logger ||= if defined? Rails
                      ActiveSupport::Logger.new(File.open("#{Rails.root}/log/rpc.log", File::WRONLY | File::APPEND | File::CREAT))
                    else
                      ::Logger.new(STDOUT)
                    end
      end

      def tag
        @tag ||= {}
      end
    end
  end
end
