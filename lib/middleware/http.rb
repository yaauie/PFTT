require 'net/http'
module Middleware
  module Http
    class Base < Base
      property :interface => 'http'

      def execute_script deployed_script
        url = translate_path deployed_script
        response = Net::HTTP.get_response( @host.address, File.relative_path( deployed_script, docroot ) )

        # handle response
        [ response.kind_of?(HTTPSuccess), response.body]
      end

      def apply_ini( php_ini )
        if super 
          @host.write( current_ini.to_a.join("\n"), ini_path )
          true
        else
          false
        end
      end

      def unset_ini()
        @host.delete ini_path
      end

      def ini_path
        @deployed_php
      end

      def ini_file
        File.join( ini_path, 'php.ini' )
      end

      def start!
        @started = true
      end

      def stop!
        @started = false
      end

      def running?
        @started || false
      end

      def restart!
        stop! unless !running?
        start!
      end
      
    end
  end
end