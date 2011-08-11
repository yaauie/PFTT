module Middleware
  module Http
    module IIS
      class FastCgi
        filter :multithreaded, false
        instantiable

        def install
          ret = super
          c_section = 'section:system.webServer'
          appcmd %Q{set config /#{c_section}/fastCGI /+[fullPath='#{@deployed_php}\\php-cgi.exe',arguments='',instanceMaxRequests='10000',maxInstances='0',monitorChangesTo='#{@deployed_php}\\php.ini']}
          appcmd %Q{set config /#{c_section}/fastCGI /+[fullPath='#{@deployed_php}\\php-cgi.exe'].environmentVariables.[name='PHPRC',value='#{@deployed_php}']}
          appcmd %Q{set config /#{c_section}/fastCGI /+[fullPath='#{@deployed_php}\\php-cgi.exe'].environmentVariables.[name='PHP_FCGI_MAX_REQUESTS',value='10000']}
          appcmd %Q{set config /#{c_section}/handlers /+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='#{@deployed_php}\\php-cgi.exe']}
          start!
          ret
        end

        def uninstall
          stop!
          appcmd %Q{clear config /section:system.webServer/fastCGI}
          appcmd %Q{set config /section:system.webServer/handlers /-[name='PHP_via_FastCGI']}
        end

        ini = <<-INI
          fastcgi.impersonate = 1
          cgi.fix_path_info=1
          cgi.force_redirect=0
          cgi.rfc2616_headers=0
        INI
      end
    end
  end
end
