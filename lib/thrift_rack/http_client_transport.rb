require 'thrift'
require 'excon'
require "stringio"
Excon.defaults[:ssl_verify_peer] = false
class ThriftRack
  class HttpClientTransport < Thrift::BaseTransport
    class RespCodeError < StandardError; end
    def initialize(client, path, opts = {})
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Thrift::Bytes.empty_byte_buffer
      @client = client
      @path = path
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << Thrift::Bytes.force_binary_encoding(buf) end

    def add_headers(headers)
      @headers = @headers.merge(headers)
    end


    def flush
      resp = @client.post(path: @path, body: @outbuf, headers: @headers, idempotent: true)
      data = resp.body
      raise RespCodeError.new("#{resp.status} on #{@path} with body #{data}") unless resp.status == 200
      data = Thrift::Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
    ensure
      @outbuf = Thrift::Bytes.empty_byte_buffer
    end
  end
end
