require 'connection_pool'
class ThriftRack
  class ExconPool
    class << self
      def pool
        @pool ||= {}
      end

      def get(url)
        @pool ||= {}
        uri = URI(url)
        @pool["#{uri.host}:#{uri.port}"] ||= ConnectionPool::Wrapper.new(size: ThriftRack::Client.pool_size, timeout: ThriftRack::Client.pool_timeout) {Excon.new("#{uri.scheme}://#{uri.host}:#{uri.port}", persistent: true)}
      end
    end
  end
end
