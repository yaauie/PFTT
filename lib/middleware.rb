module Middleware
  class Base
    # make it so the class itself can be filtered.
    # Usage:
    # ```ruby
    #   class Middleware::Foo << Middleware::Base
    #     requires :platform, :posix
    #     requires :threadsafe, true
    #     # ...
    #   end
    # ```
    class << self
      def [] key
        ancestors = self.ancestors.to_a
          ancestors.each do |ancestor|
          next false unless ancestor.respond_to? :filterable
          next false unless ancestor.filterable.has_key? key
          next false unless !ancestor.filterable[key].nil?
          return ancestor.filterable[key]
        end
        nil
        end
      end

      def []= key, *val
        (filterable)[key]=val
      end

      def requires key, *val
        self[key] = val
      end

      protected

      def filterable
        @filterable ||= Hash[[:multithreaded,:platform].zip([nil])]
      end
    end

    # make an easy way to set hierarchihcal ini
    class << self
      def ini= config
        @ini = config
      end

      def ini(inherited=true)
        if inherited
          compiled = PhpIni.new()
          ancestors.reverse_each do |ancestor|
            next false unless ancestor.respond_to? :ini
            compiled.configure ancestor.ini(false)
          end
          compiled
        else
          @ini || nil
        end
      end
    end

    # now start defining our base

    def initialize( host, php_build )
      @host = host
      @php_build = php_build
    end

    def _deploy_php_bin
      @deployed_location Host::Local.deploy(php_build.path).to(@host,@host.tmpdir)
    end

    def undeploy_php_bin
      @host.delete( @deployed_location )
    end

    def install()
      _deploy_php_bin
    end

    def uninstall()
      _undeploy_php_bin
    end

    # returns true if the ini was changed.
    # this is so that server-based installs can get restarted.
    # the php_ini should be whatever is *on top* of this class' compiled ini.
    def apply_ini( php_ini )
      new_ini = ini.configure ( php_ini || [] )
      if new_ini == current_ini
        return false
      else
        @current_ini = new_ini
      end
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
      ;date.timezone is not in the defaults from run-tests.php,
      ;but 5.3 test cases require this to be set, and doing so 
      ;seems to eliminate some failures
      date.timezone=UTC
    INI

  end
end