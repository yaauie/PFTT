module Middleware
  module Http
    module Apache
      class Base < Base
        def config_file
          (@host[:platform]==:windows ? 'C:/Apache22/' : '/etc/httpd/') + '/conf/httpd.conf'
        end

        def docroot
          (@host[:platform]==:windows ? 'C:/Apache22/htdocs' : '/var/www')
        end

        def apache_ctl args
          (@host[:platform]==:windows ? 'C:/Apache22/bin/httpd' : '/usr/bin/apache')
        end

        def initialize( *args )
          ret = super
          case @host[:platform]
          when :windows then instance_eval{include Ctl::Windows}
          when :posix then instance_eval{include Ctl::Posix}
          else raise ConfigurationError, 'For Apache, host must be either :windows or :posix'
          end
          ret
        end
      end
    end
  end 
end