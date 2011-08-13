module Middleware
  module Http
    module Apache
      class ModPhp < Base
        requirement :threadsafe => true
        instantiable

        def install
          self.instance_exec( @host[:platform]==:windows ? Ctl::Windows : Ctl ){|mod|include mod}
          super
          @apache_config_backup = @host.read( config_file )
          config = @apache_config_backup + <<-CONF
            #BEGIN:PFTT
            LoadModule php5_module "#{File.join(@deployed_php,php5apache2_2.dll)}"
            AddType application/x-httpd-php .php
            PHPIniDir "#{ini_path}/"
            #END:PFTT
          CONF
          @host.write config
          start!
        end

        def uninstall
          @host.delete config_file
          @host.write @apache_config_backup, config_file
        end
        
        def apply_ini php_ini
          applied = super
          restart! if applied and running?
          applied
        end
      end
    end
  end
end