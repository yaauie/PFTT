module Middleware
  class Cli < Base
    instantiable
    property :interface => 'cli'

    def initialize *args
      self.docroot = '/pftt-scripts'
      puts self.docroot.inspect
      super
    end

    def php_binary
      File.join( @deployed_php, case @host.properties['platform'].to_sym
      when :windows then 'php.exe'
      when :posix then 'php'
      end)
    end

    # MUST return an array like this:
    # 
    # [ status, 'hello, world!' ]
    # 
    def execute_php_script deployed_script 
      o,e,s = @host.exec!( [
            self.php_binary,
          current_ini.to_a.map{|directive| %Q{-d #{@host.escape(directive)}}},
          deployed_script
        ].flatten.compact.join(' '),
        #{:timeout=>30} # register disinterest. 
      )
      #[o,e,s].each{|x| puts x.inspect}
      [s.success?,( o + e )]
    rescue Timeout::Error
      [false, 'operation timed out.']
    end

    def deploy_path
      @script_deploy_path||= @host.tmpdir
    end
  end
end
