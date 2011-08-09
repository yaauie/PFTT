module Host
  module Remote
    class Base < Host::Base
      def initialize connection_options={}, properties={}
        @options = connection_options.dup
        super ({:local=>false}.merge(properties))
      end
    end
  end
end