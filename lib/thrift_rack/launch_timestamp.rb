class ThriftRack
  class LaunchTimestamp
    def initialize(app)
      @app = app
    end

    def call(env)
      env['LAUNCH_AT'] = Time.now
      @app.call(env)
    end
  end
end
