require 'logger'
require 'json'
class ThriftRack
  class Logger
    def initialize(app)
      @app = app
    end

    def call(env)
      request_at = req.env['LAUNCH_AT'] || Time.now
      req = Rack::Request.new(env)
      resp = @app.call(env)
      resp
    ensure
      end_time = Time.now
      ThriftRack::Logger.logger.info(
        JSON.dump(
          request_at: request_at.iso8601(6),
          request_id: req.env["HTTP_X_REQUEST_ID"],
          rpc_id: req.env["HTTP_X_RPC_ID"],
          duration: ((end_time - request_at) * 1000).round(4),
          path: req.path,
          func: req.env["HTTP_X_RPC_FUNC"],
          from: req.env["HTTP_X_FROM"],
          tag: Logger.tag,
        ),
      )
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
