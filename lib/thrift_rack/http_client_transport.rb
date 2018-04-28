require 'excon'
require "stringio"
Excon.defaults[:ssl_verify_peer] = false
class ThriftRack
  class HttpCLientTransport < Thrift::HTTPClientTransport
    def initialize(url, opts = {})
      super
      @client = Excon.new(url, persistent: true)
    end

    def flush
      resp = @client.post(body: @outbuf, headers: @headers, idempotent: true)
      data = resp.body
      data = Thrift::Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
    ensure
      @outbuf = Thrift::Bytes.empty_byte_buffer
    end
  end
end
