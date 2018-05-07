require 'thrift'
require "stringio"
require 'typhoeus'
class ThriftRack
  class HttpClientTransport < Thrift::BaseTransport
    class RespCodeError < StandardError; end
    def initialize(url, opts = {})
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Thrift::Bytes.empty_byte_buffer
      @url = url
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << Thrift::Bytes.force_binary_encoding(buf) end

    def add_headers(headers)
      @headers = @headers.merge(headers)
    end


    def flush
      resp = Typhoeus.post(@url, body: @outbuf, headers: @headers, ssl_verifypeer: false)
      data = resp.body
      raise RespCodeError.new("#{resp.code} on #{@url} with body #{data}") unless resp.code == 200
      data = Thrift::Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
    ensure
      @outbuf = Thrift::Bytes.empty_byte_buffer
    end
  end
end
