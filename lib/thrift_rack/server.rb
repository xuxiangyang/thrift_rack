class ThriftRack
  class Server
    def initialize(request = nil)
      @_request = request = nil
    end

    class << self
      def inherited(subclass)
        warn "Your class should end with Server not it is #{subclass}" unless subclass.name.end_with?("Server")
        @children ||= []
        @children << subclass
        super
      end

      def children
        @children ||= []
      end

      def inspect
        return super if self == ThriftRack::Server
        "#{self.name}(processor_class=#{self.processor_class},mount_path=#{self.mount_path})"
      end

      def processor_class
        promissory_class_name = "Thrift::#{thrift_namespace}::#{thrift_namespace}Service::Processor"
        if Kernel.const_defined?(promissory_class_name)
          Kernel.const_get(promissory_class_name)
        else
          raise "You should overwrite processor_class for #{self}"
        end
      end

      def protocol_factory
        Thrift::CompactProtocolFactory.new
      end

      def mount_path
        return thrift_namespace unless /^[A-Z]/ =~ thrift_namespace
        path = thrift_namespace.scan(/[A-Z][a-z]*/).join("_").downcase
        "/#{path}"
      end

      def thrift_namespace
        @thrift_namespace ||= self.name.scan(/[^\:]+$/).first.to_s.gsub(/Server$/, "").freeze
      end
    end
  end
end
