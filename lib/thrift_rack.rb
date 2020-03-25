require "thrift_rack/version"
require "thrift_rack/server"
require 'thrift_rack/sentry'
require "thrift_rack/logger"
require "thrift_rack/client"
require 'thrift_rack/launch_timestamp'
require 'thrift_rack/ping'
require 'thrift_rack/atom'
require 'thrift_rack/format_check'
require 'thrift_rack/server_metric'
require 'thrift_rack/http_client_transport'
require 'thrift_rack/downgrade'

require 'rack'
require 'thrift'
require 'redis'

class ThriftRack
  THRIFT_HEADER = "application/x-thrift"

  def initialize(servers = nil)
    servers ||= ThriftRack::Server.children
    @maps = {}
    servers.each do |server|
      @maps[server.mount_path] = server
    end
  end

  def call(env)
    req = Rack::Request.new(env)
    Thread.current["request"] = req
    server_class = @maps[req.path]
    return 400, {'Content-Type' => 'text/plain'}, ["No Thrift Server For #{req.path}"]  unless server_class

    resp = Rack::Response.new([], 200, {'Content-Type' => THRIFT_HEADER})

    transport = Thrift::IOStreamTransport.new req.body, resp
    protocol = server_class.protocol_factory.get_protocol transport
    server_class.processor_class.new(server_class.new(req)).process(protocol, protocol)

    resp_a = resp.to_a
    [resp_a[0], resp_a[1], [resp_a[2].join]]
  ensure
    Thread.current["request"] = nil
  end
  class << self
    attr_writer :redis

    def app(servers = nil)
      Rack::Builder.new(ThriftRack.new(servers)) do
        use ThriftRack::Downgrade
        use ThriftRack::LaunchTimestamp
        use ThriftRack::Ping
        use ThriftRack::FormatCheck
        use ThriftRack::Atom
        use ThriftRack::Logger
        use ThriftRack::ServerMetric
        use ThriftRack::Sentry if defined? Raven
      end
    end

    def redis
      @redis ||= Redis.new
    end
  end
end
