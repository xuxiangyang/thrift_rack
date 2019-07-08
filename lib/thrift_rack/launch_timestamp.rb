class ThriftRack
  class LaunchTimestamp
    def initialize(app)
      @app = app
    end

    def call(env)
      env['LAUNCH_TIMESTAMP'] = Time.now.iso8601(6)
      @app.call(env)
    end
  end
end
