class ThriftRack
  class Downgrade
    def initialize(app)
      @app = app
      @drop_percentage = 0
      @last_sync_drop_percentage_at = Time.at(0)
    end

    def call(env)
      if rand(100) < drop_percentage
        [509, {}, ["Downgrading"]]
      else
        @app.call(env)
      end
    end

    private

    def drop_percentage
      if Time.now - @last_sync_drop_percentage_at > 3
        @last_sync_drop_percentage_at = Time.now
        @drop_percentage = self.class.current_drop_percentage
      else
        @drop_percentage
      end
    end

    class << self
      def change_downgrade(drop_percentage)
        ThriftRack.redis.set(downgrade_redis_key, drop_percentage)
      end

      def current_drop_percentage
        ThriftRack.redis.get(downgrade_redis_key).to_f
      end

      def close_downgrade
        ThriftRack.redis.del(downgrade_redis_key)
      end

      def downgrade_redis_key
        "thrift_rack:downgrade"
      end
    end
  end
end
