module Middleware
  class Cli < Base
    def execute_script local_script 
      remote_script = Host::Local.deploy( local_script ).to( @host, @host.tmpdir )
      
      e,o,w = @host.exec_and_wait( [
          self.php_binary,
          @current_ini.to_a.map{|directive| "-d #{directive}"},
          remote_script
        ].flatten.compact.join(' ') 
      )

      @host.delete(remote_script_address)
    end
  end
end