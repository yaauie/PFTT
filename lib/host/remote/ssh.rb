module Host
  module Remote
    class Ssh < Host::Remote::Base
      def wrap( command )
        "#{_connection_string} #{command}"
      end

      def _connection_string
        if !@connection
          connection=[]
          connection << "-i #{@options[:identity]}"
          connection << "#{@options[:user]}@#{@options[:hostname]}"
          @connection = connection.join(' ')
        end
        @connection
      end
    end
  end
end