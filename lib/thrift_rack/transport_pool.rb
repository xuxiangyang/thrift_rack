require 'connection_pool'
class ThriftRack
  class TransportPool
    class << self
      def pool
        @pool ||= {}
      end

      def get(url)
        @pool ||= {}
        uri = URI(url)
        @pool["#{uri.host}:#{uri.port}"] ||= ConnectionPool::Wrapper.new(size: ThriftRack::Client.pool_size, timeout: ThriftRack::Client.pool_timeout) {ThriftRack::HttpCLientTransport.new(url)}
      end
    end
  end
end
