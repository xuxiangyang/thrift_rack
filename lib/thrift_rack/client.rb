require 'securerandom'
class ThriftRack
  class Client
    def initialize(url, client_klass, request_id = nil)
      @request_id = request_id || "no-request"
      @url = url
      @transport = ThriftRack::HttpClientTransport.new(url)
      protocol = protocol_factory.get_protocol(@transport)
      @client = client_klass.new(protocol)
    end

    def protocol_factory
      Thrift::CompactProtocolFactory.new
    end

    def respond_to_missing?(method, _include_private = false)
      @client.respond_to?(method)
    end

    def method_missing(method, *params)
      return super unless @client.respond_to?(method)

      self.class_eval do
        define_method method.to_sym do |*args|
          begin
            rpc_id = SecureRandom.uuid
            request_at = Time.now
            @transport.add_headers("X-Request-ID" => @request_id, "X-Rpc-ID" => rpc_id, "X-Rpc-Func" => method.to_s, "X-From" => ThriftRack::Client.app_name || "unknown")
            @client.send(method, *args)
          ensure
            end_time = Time.now
            duration = (end_time - request_at) * 1000
            process_duration = @transport.response_headers["x-server-process-duration"]&.to_f
            ThriftRack::Client.logger.info(
              JSON.dump(
                request_at: request_at.iso8601(6),
                request_id: @request_id,
                rpc_id: rpc_id,
                duration: duration.round(4),
                path: URI(@url).path,
                func: method,
                tag: ThriftRack::Client.logger_tag,
                server: {
                  id: @transport.response_headers["x-server-id"],
                  private_ip: @transport.response_headers["x-server-private-ip"],
                  process_duration: process_duration ? process_duration.round(4) : nil,
                  network_duration: process_duration ? (duration - process_duration).round(4) : nil,
                },
              ),
            )
          end
        end
      end
      self.public_send(method, *params)
    end

    class << self
      attr_writer :app_name, :logger_tag

      def app_name
        @app_name ||= Rails.application.class.parent.name.underscore if defined? Rails
        @app_name
      end

      def logger_tag
        @logger_tag || {}
      end

      def logger
        @logger ||= if defined? Rails
                      ActiveSupport::Logger.new(File.open("#{Rails.root}/log/rpc_client.log", File::WRONLY | File::APPEND | File::CREAT))
                    else
                      ::Logger.new(STDOUT)
                    end
      end

      def config(app_name, max_requests: 100, logger_tag: {})
        self.app_name = app_name
        self.logger_tag = logger_tag
        HttpClientTransport.default = HttpClientTransport.new_http(name, max_requests)
        at_exit do
          ThriftRack::Client.logger.close
        end
      end
    end
  end
end
