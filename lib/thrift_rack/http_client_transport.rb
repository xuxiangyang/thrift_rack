require 'thrift'
require "stringio"
require 'net/http/persistent'
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
      uri = URI(@url)
      post = Net::HTTP::Post.new uri.path
      post.body = @outbuf
      post.initialize_http_header(@headers)
      resp = retry_request_with_503{ThriftRack::HttpClientTransport.default.request(uri, post)}
      data = resp.body
      raise RespCodeError.new("#{resp.code} on #{@url} with body #{data}") unless resp.code.to_i == 200
      data = Thrift::Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
    ensure
      @outbuf = Thrift::Bytes.empty_byte_buffer
    end

    def retry_request_with_503
      resp = nil
      3.times do |i|
        resp = yield
        if resp.code.to_i != 503
          return resp
        end
        sleep(0.1 * i)
      end
      resp
    end

    class << self
      attr_accessor :default

      def default
        return @default if @default
        @default = Net::HTTP::Persistent.new
        @default.verify_mode = 0
        @default
      end
    end
  end
end
