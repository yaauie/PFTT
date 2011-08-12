module Middleware
  class Base
    
    include TestBenchFactor
    include PhpIni::Inheritable

    def ini(arg=nil)
      ret = super
      # if we're getting the whole stack, push the extensions_dir to the *top*.
      PhpIni.new(%Q{extension_dir="#{@deployed_php}/ext"}).configure(ret) if arg.nil?
      ret
    end

    # now start defining our base
    def initialize( host, php_build )
      @host = host
      @php_build = php_build
    end

    def _deploy_php_bin
      @deployed_php = Host::Local.deploy(php_build.path).to(@host,@host.tmpdir)
    end

    def _undeploy_php_bin
      @host.delete( @deployed_location )
    end

    def install()
      _deploy_php_bin
      apply_ini
    end

    def uninstall()
      _undeploy_php_bin
      unset_ini
    end

    def deploy_script( local_file )
      @deployed_scripts||=[]
      @deployed_scripts << Host::Local.deploy( local_file ).to( @host, deploy_path )
    end

    def undeploy_script()
      @deployed_scripts.reject! do |script|
        @host.delete script
      end
    end

    # returns true if the ini was changed.
    # this is so that server-based installs can get restarted.
    # the php_ini should be whatever is *on top* of this class' compiled ini.
    def apply_ini( php_ini=[] )
      @base_ini ||= @host.ini << self.ini << @php.ini
      new_ini = @base_ini << ( php_ini || [] )
      if new_ini == current_ini
        return false
      else
        @current_ini = new_ini
      end
    end

    def unset_ini
      @current_ini = []
    end

    def current_ini
      @current_ini ||= []
    end

    ini= <<-INI
      output_handler=
      open_basedir=
      safe_mode=0
      disable_functions=
      output_buffering=Off
      error_reporting= E_ALL | E_STRICT
      display_errors=1
      display_startup_errors=1
      log_errors=0
      html_errors=0
      track_errors=1
      report_memleaks=1
      report_zend_debug=0
      docref_root=
      docref_ext=.html
      error_prepend_string=
      error_append_string=
      auto_prepend_file=
      auto_append_file=
      magic_quotes_runtime=0
      ignore_repeated_errors=0
      precision=14
      unicode.runtime_encoding=ISO-8859-1
      unicode.script_encoding=UTF-8
      unicode.output_encoding=UTF-8
      unicode.from_error_mode=U_INVALID_SUBSTITUTE
    INI

  end

  All = TypedArray( Middleware::Base )
end

# Load up all of our middleware classes right away instead of waiting for the autoloader
# this way they are actually available in Middleware::All
# although it technically does not matter the order in which they are loaded (as they will trigger
# autoload events on missing constants), reverse tends to get shallow before deep and should improve
# performance, if only marginally.
Dir.glob File.join( File.dirname(__FILE__), 'middleware/**/*.rb')).reverse_each &method(:require)
