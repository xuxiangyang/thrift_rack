require 'logger'
require 'json'
class ThriftRack
  class Logger
    def initialize(app)
      @app = app
    end

    def call(env)
      request_at = Time.now
      req = Rack::Request.new(env)
      resp = @app.call(env)
      resp
    ensure
      end_time = Time.now
      self.logger.info(JSON.dump({
        request_at: request_at.iso8601(6),
        request_id: req.env["HTTP_X_REQUEST_ID"],
        rpc_id: req.env["HTTP_X_RPC_ID"],
        duration: ((end_time - request_at) * 1000).round(4),
        path: req.path,
        func: req.env["HTTP_X_RPC_FUNC"],
        from: req.env["HTTP_X_FROM"],
        tag: Logger.tag,
      }))
    end

    def logger
      @logger ||= (defined? Rails) ? rails_logger : std_logger
    end

    private

    def rails_logger
      file = File.open("#{Rails.root}/log/rpc.log", File::WRONLY | File::APPEND | File::CREAT)
      file.sync = true
      ActiveSupport::Logger.new(file)
    end

    def std_logger
      ::Logger.new(STDOUT)
    end

    class << self
      attr_writer :tag
      def tag
        @tag ||= {}
      end
    end
  end
end
