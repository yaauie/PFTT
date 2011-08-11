module Middleware
  module Http
    module Apache
      module Ctl
        module Windows
          def start!
            @host.exec! 'net start Apache2.2'
            super
          end
          def stop!
            @host.exec! 'net stop Apache2.2'
            super
          end
        end

        module Posix
          def start!
            @host.exec! '/etc/init.d/apache2 start'
            super
          end

          def stop!
            @host.exec! '/etc/init.d/apache2 stop'
            super
          end

          def restart!
            @host.exec! '/etc/init.d/apache2 restart'
            super
          end
        end
      end
    end
  end
end