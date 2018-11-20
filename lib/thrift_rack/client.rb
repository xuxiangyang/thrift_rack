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
            ThriftRack::Client.logger.info(
              JSON.dump(
                request_at: request_at.iso8601(6),
                request_id: @request_id,
                rpc_id: rpc_id,
                duration: ((end_time - request_at) * 1000).round(4),
                path: URI(@url).path,
                func: method,
              ),
            )
          end
        end
      end
      self.public_send(method, *params)
    end

    class << self
      attr_accessor :app_name
      attr_reader :pool_size

      def logger
        @logger ||= if defined? Rails
                      ActiveSupport::Logger.new(File.open("#{Rails.root}/log/rpc_client.log", File::WRONLY | File::APPEND | File::CREAT))
                    else
                      ::Logger.new(STDOUT)
                    end
      end

      def pool_size=(p)
        http = Net::HTTP::Persistent.new(name: self.app_name, pool_size: p)
        http.retry_change_requests = true
        http.max_requests = 100
        http.verify_mode = 0
        HttpClientTransport.default = http
        @pool_size = p
      end
    end
  end
end
