module Middleware
  module Http
    module IIS
      class Base < Base
        requirement :platform => :windows
        def docroot;'C:/inetpub/wwwroot/';end
        def app_cmd args
          @host.exec! "C:/%WINDIR%/System32/inetsrv/appcmd #{args}"
        end

        def start!
          @host.exec! 'net start w3svc'
        end
        def stop!
          @host.exec! 'net start w3svc'
        end
        def restart!
          stop! unless !runing?
          start!
        end
      end
    end
  end 
end
