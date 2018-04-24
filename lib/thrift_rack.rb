require "thrift_rack/version"
require "thrift_rack/server"
require 'rack'
require 'thrift'


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
    return Rack::Response.new(["PONG"], 200, {'Content-Type' => 'text/plain'}) if req.path == "/ping"

    return Rack::Response.new(["Not Valid Thrift Request"], 400, {'Content-Type' => 'text/plain'}) unless req.post? && req.env["CONTENT_TYPE"] == THRIFT_HEADER

    server_class = @maps[req.path]
    return Rack::Response.new(["No Thrift Server For #{req.path}"], 404, {'Content-Type' => 'text/plain'}) unless server_class

    resp = Rack::Response.new([], 200, {'Content-Type' => THRIFT_HEADER})

    transport = Thrift::IOStreamTransport.new req.body, resp
    protocol = server_class.protocol_factory.get_protocol transport
    server_class.processor_class.new(server_class.new).process(protocol, protocol)

    resp
  end

  def self.app(servers = nil)
    Rack::Builder.new(ThriftRack.new(servers)) do
      use Rack::CommonLogger
      use Rack::ShowExceptions
      use Rack::Lint
    end
  end
end
