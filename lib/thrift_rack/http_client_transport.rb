require 'thrift'
require "stringio"
require 'net/http/persistent'
class ThriftRack
  class HttpClientTransport < Thrift::BaseTransport
    class RespCodeError < StandardError; end
    class ProcessedRequest < RespCodeError; end
    class ServerDowngradingError < RespCodeError; end

    attr_accessor :response_headers
    def initialize(url, opts = {})
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Thrift::Bytes.empty_byte_buffer
      @response_headers = {}
      @url = url
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << Thrift::Bytes.force_binary_encoding(buf) end

    def add_headers(headers)
      @headers = @headers.merge(headers)
    end

    def flush
      self.response_headers = {}
      uri = URI(@url)
      post = Net::HTTP::Post.new uri.path
      post.body = @outbuf
      post.initialize_http_header(@headers)
      resp = retry_request_with_503{ThriftRack::HttpClientTransport.default.request(uri, post)}
      data = resp.body
      self.response_headers = resp.header
      resp_code = resp.code.to_i
      if resp_code != 200
        if resp_code == 409
          raise ProcessedRequest, @url
        elsif resp_code == 509
          raise ServerDowngradingError, @url
        else
          raise RespCodeError, "#{resp.code} on #{@url} with body #{data}"
        end
      end
      data = Thrift::Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
    ensure
      @outbuf = Thrift::Bytes.empty_byte_buffer
    end

    def retry_request_with_503
      resp = nil
      3.times do |i|
        resp = yield
        return resp unless resp.code.to_i == 503

        sleep(0.1 * i)
        ThriftRack::HttpClientTransport.default.reconnect
      end
      resp
    end

    class << self
      attr_accessor :default

      def default
        @default ||= new_http
      end

      def new_http(name, max_requests: 100)
        http = Net::HTTP::Persistent.new(name)
        http.retry_change_requests = true
        http.max_requests = max_requests
        http.verify_mode = 0
        http
      end
    end
  end
end
