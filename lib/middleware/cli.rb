module Middleware
  class Cli < Base
    instantiable

    # MUST return an array like this:
    # 
    # [ status, 'hello, world!' ]
    # 
    def execute_script deployed_script 
      o,e,s = @host.exec_and_wait( [
            self.php_binary,
          @current_ini.to_a.map{|directive| "-d #{directive}"},
          File.join( docroot, deployed_script )
        ].flatten.compact.join(' '),
        {:timeout=>30} # register disinterest. 
      )
      s.success?,( o + e )
    rescue Timeout::Error
      false, 'operation timed out.'
    end

    def deploy_path
      @script_deploy_path||= @host.tmpdir
    end
  end
end
