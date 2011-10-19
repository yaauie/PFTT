
# PFTT - the Practically-Formulated-Test-Tool
#
# Network System Topology
#  host - runs the tests received by client
#  server - coordinates access to host pools and shares tests, binaries and configurations with clients 
#  client - runs the tests on hosts
#
#  may combine client+host (ie run tests on localhost). may do client+localhost and other hosts and optionally a server
#  may have client(s) and host(s) without a server
#  may only have one server
#

# some mysql and pdo tests modify a shared database so they can't be threaded
$single_threaded_tests = ['ext/standard/tests/http', 'ext/phar', 'mysql', 'pdo']


##
  
$version = 0.1
$release = '054107102011'

# TODO be able to provide a build filter and have PFTT get build from server
#        and leave out --phpt-dir and --php-dir

# TODO auto-triage
#   if :delete with 'array(' or 'string('
#   if :insert with 'array(' or 'string(' 
#   if :delete with warning
#      if a corresponding :insert
#           type=>'warning change'
#      else
#           type=>'warning missing'
#   if :insert with warning
#      type=>'warning added'
#
# report with:
#  count of :equals vs :delete vs :insert for each test (show next to name of test when test is run)
#  count of :equals vs :delete vs :insert for all tests
#  tally up occurances of each type
#  tally up tests with 1+ of each type
#  tally up number of passed and failed tests 
#

## begin pftt

require File.join(File.dirname(__FILE__),'bootstrap.rb')

$db_file = "#{APPROOT}/all_pftt_results.sqlite"

require 'optparse'
require 'pp'
require 'rbconfig'

class String
  def convert_path
    self.gsub('\\','/')
  end
  def convert_path!
    self.gsub!('\\','/')
  end
  def self.not_nil(a)
    if a==nil
      ''
    else
      a
    end
  end
end

$client = PfttClient.new()

require 'rbconfig'

$thread_pool_size =  1 # TODO doing lots of thread creates/exits if != 1
$brief_output = false
$skip_none = false
$force_deploy = false
$debug_test = false
$html_report = false
$interactive_mode = false
$is_windows = RbConfig::CONFIG['host_os'].include?('mingw') or RbConfig::CONFIG['host_os'].include?('mswin')
  
class PfttOptions < OptionsHash

  def self.parse(args)
    default_config_file = "#{APPROOT}/config/default.yaml"
    
    options = PfttOptions.new
    
    if args.length < 1
      puts 'PFTT: must specify an action'
      options.help_list_actions
      exit(4)
    end
    
    # TODO
    options.replace(YAML::load( File.open(default_config_file) )) unless !File.exists?( default_config_file )
    
    options[:action] = args[0]
    case options[:action]
    when 'func_full'
      options.parse_func(args)
      $force_deploy = true
    when 'func_part'
      options.parse_func(args)
    when 'func_inspect'
      options.parse_func(args)
    when 'func_list'
      options.parse_func_list(args)
    when 'mi'
      # LATER make ini
      #   generates INI for given scenario+build
    when 'cs'
      # LATER
    when 'hc'
      # LATER
    when 'perf'
    when 'unit'
    when 'ui'
    when 'stress'
    when 'net_view'
      options.parse_net_view(args)
    when 'net_lock'
      options.parse_lock_release(args)
    when 'net_release'
      options.parse_lock_release(args)
    when 'update_config'
    when 'upgrade'
    when 'example'
      puts
      puts 'pftt func_full --php-dir <dir> --phpt-dir <dir>'
      puts
      puts 'pftt func_part --php-dir <dir> --phpt-dir <dir> --tests ext/curl'
      puts
      #
      if $is_windows
        puts 'set PHPT_DIR=c:\php-sdk\svn\branches\PHP_5_4'
        puts 'set PHP_DIR=C:\php-sdk\php-5.4.0beta1-nts-Win32-VC9-x86'
        puts 'pftt func_list --test-list list1.txt --phpt-dir %PHPT_DIR% --tests fileinfo'
        puts 'notepad list1.txt'
        puts 'pftt func_part --php-dir %PHP_DIR% --phpt-dir %PHPT_DIR% --test-list list1.txt'
      else
        puts 'export PHPT_DIR=~/php-sdk/svn/branches/PHP_5_4'
        puts 'export PHP_DIR=~/php-sdk/php-5.4.0beta1-nts-Win32-VC9-x86'
        puts 'pftt func_list --test-list list1.txt --phpt-dir $PHPT_DIR --tests fileinfo'
        puts 'vi list1.txt'
        puts 'pftt func_part --php-dir $PHP_DIR --phpt-dir $PHPT_DIR --test-list list1.txt'
      end
      #
      puts
      exit(4)
    when 'help'
      if args.length < 2
        puts 'PFTT: for action specific help, run '
        puts 'PFTT: pftt help [action]'
        options.help_list_actions
        exit(4)
      end
      
      options[:help_action] = args[1]
      case options[:help_action]
      when 'func_full'
        options.help_func(args)
      when 'func_part'
        options.help_func(args)
      when 'func_inspect'
        options.help_func(args)
      when 'func_list'
        options.help_func_list
      when 'cs'
        # LATER
      when 'hc'
        # LATER
      when 'perf'
      when 'unit'
      when 'ui'
      when 'stress'
      when 'net_view'
        options.help_net_view(args)
      when 'net_lock'
        options.help_lock_release(args)
      when 'net_release'
        options.help_lock_release(args)
      when 'update_config'
      when 'upgrade'
      when 'help'
      else
        puts 'PFTT: invalid action '+options[:help_action]
        options.help_list_actions
      end
      
      exit(4)
    else
      if options[:action]
        puts 'PFTT: invalid action '+options[:action]
      else
        puts 'PFTT: must specify an action!'
      end
      puts 'PFTT: pftt [action]'
      
      options.help_list_actions
      
      exit(4)
    end
    
    # TODO does it make sense to load config file here??
    #options.replace(YAML::load( File.open(default_config_file) )) unless !File.exists?( default_config_file ) 
    
    options
  end
    
  def help_list_actions
    puts
    puts '  func_part     - runs selected PHPT tests (ex: manual tool)'
    puts '  func_full     - deploys PHP and runs PHPT tests (ex: automatic tool)'
    puts '  func_list     - write list of PHPT tests to file. useful with func_part'
    puts '  func_inspect  - inspects options/configs used for func_part or func_full'
    puts '  perf          - run Performance test'
    puts '  stress        - run Stress test'
    puts '  unit          - run PHPUnit tests from PHP-AzureSDK, MediaWiki, Symfony, etc'
    puts '  ui            - run automated UI tests (app compat)'
    #puts '  cs            - ' # LATER
    #puts '  hc            - ' # LATER
    puts
    # only show net_view net_lock net_release update_config when PFTT server configured
    if $client
    puts '  net_view      - shows list of PFTT hosts registered with your PFTT Server'
    puts '  net_lock      - locks a PFTT host so only this client may use it'
    puts '  net_release   - releases a lock on a PFTT host (undoes net_lock)'
    puts '  update_config - downloads newest Client Configuration from your PFTT Server'
    end
    puts '  upgrade       - upgrades this PFTT client to the newest PFTT version'
    puts '  help          - help'
    puts '  example       - shows example commands'
    puts
  end
  
  def help_lock_release(args)
    puts 'PFTT: Usage: pftt #{args[0]} [hostname1][ hostname2][ hostname3]'
    puts
    puts 'Notifies the PFTT Server to lock/release the named host(s)'
    puts
  end
  
  def parse_lock_release(args)
    if args.length < 2
      puts 'PFTT: error: must specify hostname!'
      help_lock_release(args)
      exit(-4)
    end
    
    self[:target_host_name]||=[]
    args.shift.each{|host_name|
      self[:target_host_name].push(host_name)
    }
  end
  
  def help_net_view(args)
    puts opts_net_view(args).to_s
    puts
  end
  
  def parse_net_view(args)
    opts_net_view(args).parse(args)
  end
  
  def opts_net_view(args)
    opts = OptionParser.new do |opts|
      opts.banner = 'PFTT: Usage: pftt net_view [optional filters]'
      
      opts.separator ''
      opts.separator 'Filters:'
      
      opts.on(
        '--hosts <HOST>[,<HOST>[,...]]',
        Array
      ) do |hosts|
        self[:hosts]||=[]
        self[:hosts].concat hosts
      end
            
      opts.on(
        '--platform <PLATOFRM>[,<PLATFORM>]',
        Array
      ) do |platforms|
        self[:php,:filters,:platform]||= []
        self[:php,:filters,:platform].concat platforms
      end
    end
    
    opts
  end
  
  def opts_func(help, action)
    opts = OptionParser.new do |opts|
      opts.banner = "PFTT: Usage: pftt #{action} [options]"
        
      opts.separator ''
      opts.separator 'Specific Options:'

      if !help or action != 'func_list'
        # for func_list help, don't show these options
        # for func_list, parse them anyway and ignore them (user can just change action not delete arguments)
        opts.on(
          '--force-deploy',
          'Forces PFTT to deploy tests and binaries before testing. Otherwise, func_part will run the binaries and tests from their stored location (so as to speed up partial testing). func_full ignores this option (and always deploys).'
        ) do
          $force_deploy = true
        end
              
        opts.on(
          '--debug',
          'Uses WinDbg or GDB to debug PHP while its running tests (usually only used with func_part).'
        ) do
          $debug_test = true
        end
              
        opts.on(
          '--brief',
          'Limits the amount of output. Otherwise, there may be a lot of output.'
        ) do
          $brief_output = true
        end
              
        opts.on(
          '--skip-none',
          'Forces all PHPT tests to be run regardless of what their SKIPIF sections return(SKIPIF sections are NOT run).'
        ) do
          $skip_none = true
        end
              
        opts.on(
          '--db-file',
          "specifiy the file to write result data to (SQLite3 file format). Default #{$db_file}."
        ) do |db_file|
          $db_file = db_file
        end
        
        opts.on(
          '--clear',
          'Clear the loaded configuration entirely. Helpful for scenarios in which you do not want to use the default configuration, or want to clear out a particular setting.'
        ) do
          clear # TODO
        end
              
        opts.on(
          '-c',
          '--config <FILE>',
          'Load a .yml config file into the current options.'
        ) do |config|
          merge! YAML::load( config )
        end
      
        opts.on(
          '--php-dir DIRECTORY',
          'set the directory in which to look for php builds.'
        ) do |php_dir|
          require_dir(php_dir)
          
          self[:php,:dir] = php_dir
        end
      
      end
      
      opts.on(
        '--phpt-dir <dir>[,<dir>[,...]]',
        Array
      ) do |test_globs|
        self[:phpt]||=[]
        self[:phpt] = [self[:phpt]] unless self[:phpt].is_a? Array
        self[:phpt].concat test_globs
          
        test_globs.each{|path| require_dir(path) }
      end
      
      opts.on(
        '--html',
        'Generates an html copy of the final run report and displays in web browser'
      ) do
        $html_report = true
      end
      
      opts.on(
        '--tests <name>[,<name>[,...]]',
        Array,
        'Name (fragment) of tests to run'
      ) do |test_names|
        self[:test_names]||=[]
        test_names.each{|test_name| self[:test_names].push(test_name)}
      end
      
      if action!='func_full'
        # don't allow --test-list to be used with action 'func_full'
        opts.on(
          '--test-list <file>[,<file>[,...]]',
          "provide a file listing tests to run. use 'pftt func_list' to autogenerate the list."
        ) do |test_file|
          if action == 'func_part'
            # for func_part only, ensure file exists
            require_file(test_file)
          end
          
          self[:test_list_file] = test_file
        end
        
        opts.on(
          '--i[int[eractive]]',
          'Interactive Mode, breaks intto a debug prompt when different test output is encountered.'
        ) do
          $interactive_mode = true
        end
      end
      
      if !help or action != 'func_list'
        # for func_list help, don't show these options
        # for func_list, parse them anyway and ignore them (user can just change action not delete arguments)
        opts.on(
          '--hosts <HOST>[,<HOST>[,...]]',
          Array
        ) do |hosts|
          self[:hosts]||=[]
          self[:hosts].concat hosts
        end
      
        opts.separator ''
        opts.separator 'Filters:'
      
        opts.on(
          '--php-compiler <COMPILER>[,<COMPILER>[,...]]',
          Array,
          'Only include PHP Builds whose compiler matches.'
        ) do |php_compilers|
          self[:php,:filters,:compiler]||= []
          self[:php,:filters,:compiler].concat php_compilers
        end
        
        opts.on(
          '--php-threadsafe <THREADSAFETY>',
          TrueClass,
          'Only include PHP Builds whose threadsafety-ness matches.'
        ) do |threadsafety|
          self[:php,:filters,:threadsafe] = threadsafety
        end
        
        opts.on(
          '--php-version <PHPVERSION>[,<PHP_VERSION>]',
          Array
        ) do |php_versions|
          self[:php,:filters,:version]||= []
          self[:php,:filters,:version].concat php_versions
        end
        
        opts.on(
          '--php-branch <BRANCH>[,<BRANCH>]',
          Array
        ) do |php_branches|
          self[:php,:filters,:php_branch]||= []
          self[:php,:filters,:php_branch].concat php_branches
        end
        
        opts.on(
          '--platform <PLATOFRM>[,<PLATFORM>]',
          Array
        ) do |platforms|
          self[:php,:filters,:platform]||= []
          self[:php,:filters,:platform].concat platforms
        end
        
        opts.on(
          '--middleware <MIDDLEWARE>[,<MIDDLEWARE>[,...]]',
          Array
        ) do |middlewares|
          self[:middleware]||=[]
          self[:middleware].concat middlewares
        end
      end
        
      opts.on_tail(
        "-h", "--help",
        "Show this message"
      ) do
        help_func
        exit
      end
    end
    opts
  end
  
  def require_dir(dir)
    unless Dir.exists?(dir)
      puts "PFTT: error: directory not found: #{dir}"
      puts
      exit(-6)
    end
  end
  
  def require_file(file)
    unless File.exists?(file)
      puts "PFTT: error: file not found: #{file}"
      puts
      exit(-6)
    end
  end
  
  def parse_func(args)
    begin
      opts_func(false, args[0]).parse(args)
      unless self[:php,:dir]
        puts 'PFTT: error: required argument: --php-dir'
        help_func(args)
        exit(-4)
      end
      unless self[:phpt]
        puts 'PFTT: error: required argument: --phpt-dir'
        help_func(args)
        exit(-4)
      end
    rescue
      puts 'PFTT: '+$!.to_s
      help_func(args)
      exit(-1) 
    end
  end
  
  def help_func(args)
    puts
    puts opts_func(true, args[1]).to_s
    puts
  end
  
  def parse_func_list(args)
    begin
      opts_func(false, 'func_list').parse(args)
      unless self[:phpt]
        puts 'PFTT: error: required argument: --phpt-dir'
        help_func_list
        exit(-4)
      end
      unless self[:test_list_file]
        puts 'PFTT: error: required argument: --test-list'
        help_func_list
        exit(-4)
      end
    rescue
      puts 'PFTT: '+$!.to_s
      help_func_list
      exit(-1)
    end
  end
  
  def help_func_list
    puts
    puts opts_func(true, 'func_list').to_s
    puts
  end
  
  def selected_tests load_file=true, abs_path=true
    if load_file
      if self[:test_list_file]
        f = File.open(self[:test_list_file], 'rb')
        while !f.eof
          line = f.readline()
          # ignore lines starting with # lets user add comments to the list
          unless line.starts_with?('#')
            self[:test_names]||=[]
            self[:test_names].push(line)
          end
        end
      end
    end
    
    begin
      list = []
      self[:phpt].each{|phpt|
        list.push(PhptTestCase::Array.new(phpt, self[:test_names]))
      }
      return list
    rescue PhptTestCase::Array::DuplicateTestError
      puts "PFTT: error: same test occurs in multiple directories: #{file}"
      exit(-8)
    end
  end
  
end # end class PfttOptions

class ArgRewriter  
  def initialize(args)
    @args = Array.new(args)
  end
  
  def cmd(cmd)
    @args[0] = cmd
  end
  
  def add(arg, value)
  end
  
  def delete(idx)
    @args.delete(idx)
  end
  
  def remove(arg)
    @args.delete_if {|x| x == arg }
  end
  
  def replace(arg, value)
    remove(arg)
    add(arg, value)
  end
  
  def join
    'pftt '+@args.join(' ')
  end
end

# parse in the options
CONFIG = PfttOptions.parse(ARGV)

# set up our basic test bench factors
$hosts = (Host::Array.new.load(CONFIG[:host,:path].convert_path)).filter(CONFIG[:host,:filters])
$hosts.push(Host::Local.new()) # TODO
require 'typed-array'
$phps = PhpBuild.get_set(CONFIG[:php,:dir].convert_path||'').filter(CONFIG[:php,:filters])
$middlewares = [Middleware::Cli] # TODO Middleware::All#.filter([])# TODO CONFIG[:middleware,:filters])
  
# LATER? what about NFSv3 support (which ships with Windows 7<) (not NFSv4)
$scenarios = {}
# must always have at least 1 working_file_system context! (other contexts are optional)
$scenarios[:working_file_system] = [Scenario::WorkingFileSystem::Local.new()]# TODO , Scenario::WorkingFileSystem::Smb::LocalPhp.new(), Scenario::WorkingFileSystem::Smb::RemotePhp.new]
$scenarios[:remote_file_system] = []#Scenario::RemoteFileSystem::Http.new(), Scenario::RemoteFileSystem::Ftp.new()]
$scenarios[:database] = []# Scenario::Database::Mysql::Tcp.new(), Scenario::Database::Mysql::Ssl.new()]
# LATER $scenarios[:date]
  
if __FILE__ == $0
  # this file is the main file of the app (this file isn't being imported into another app)
  #
  # store all the output in pftt_last_command.txt, in case it exceeds the buffer size of the user's terminal
  # (store in whatever the current directory is)
  $last_command_file = File.open('pftt_last_command.txt', 'wb')
  # (store the exact command that was run too)
  if $is_windows
    $last_command_file.puts('REM')
    $last_command_file.puts('REM pftt '+ARGV.join(' '))
    $last_command_file.puts('REM in '+Dir.pwd)
    $last_command_file.puts('REM')
  else
    $last_command_file.puts('#')
    $last_command_file.puts('# pftt '+ARGV.join(' '))
    $last_command_file.puts('# '+Dir.pwd)
    $last_command_file.puts('#')
  end
  def save_cmd_out(str)
    $last_command_file.puts(str)
  end
  def puts(*str)
    if str.empty?
      super()
      save_cmd_out('')
    else
      str = str.join('')
      super(str)
      save_cmd_out(str)
    end
  end
  #
  #

  # TODO move these functions into class
  #     makes PFTT programmable
  def lock_all(hosts)
    unless $client
      return # no PFTT server, ignore
    end
    hosts.each{|host|
      if host.is_a?(Host::Remote)
        $client.net_lock(host[:host_name])
      end 
    }
  end
  def release_all(hosts)
    unless $client
      return # no PFTT server, ignore
    end
    hosts.each{|host|
      if host.is_a?(Host::Remote)
        $client.net_lock(host[:host_name])
      end
    }
  end
  def host_config
    return
    host = Host.new() # TODO
      
    #
    if host.windows?
      # ensure this is at least Windows XP SP3
      out_err, status = host.exec!('systeminfo')
      out_err.split('\n').each{|line|
        if line.starts_with('OS Version:')
          line = line['OS Version:'.length...line.length]
          parts = line.split(' ')
          nt_version = parts[0].to_i
          
          if nt_version < 5.1
            puts 'PFTT: host_config: host is running Windows before XP. Host must be running at least Windows XP or newer.'
            exit(-15)
          end
        end
      }
        
      # disable firewall
      puts 'PFTT: host_config: disabling windows firewall...'
      host.exec!("netsh firewall set opmode disable")
        
      # disable Dr Watson
      puts 'PFTT: host_config: disabling Dr Watson service...'
      host.exec!('regchg "software\control key\installed version" REG_SZ 1.00')
        
      # Windows: ensure VC++ redistributable x86 and x64 installed (if x64 OS, need both!)
      puts 'PFTT: host_config: checking VC++ runtime...'
      win_install(host, "vc9_vcredistx86.exe", '/passive')
      begin
        win_install(host, "vc9_vcredistx64.exe", '/passive')
      rescue
      end
      #  both are needed for PHP (vc9) to work
      #  should install here (rather than in middleware) because it just needs to be done once
        
      puts 'PFTT: host_config: ensuring Apache is installed...'
      win_install(host, "httpd-2.2.21-win32-x86-openssl-0.9.8r.msi", '/Q')
      
      puts 'PFTT: host_config: ensuring 7zip installed...'  
      win_install(host, "7z920.msi", '/Q')
      
      # TODO install elevate
      # TODO install wcat
      
      
      puts 'PFTT: host_config: ensuring IIS installed...'
      unless host.exits?('%SYSTEMDIR%/system32/inetsrv/appcmd.exe')
        # IIS is not installed. try to install it
        host.deploy('scripts/IIS/iis_unattend.xml', host.systemdrive+'/iis_unattend.xml')
        
        # TODO install from 'Windows Features' in control panel
        host.exec!('pkgmgr /n:'+host.systemdrive+'/iis_unattend.xml')
        # see: http://learn.iis.net/page.aspx/133/using-unattended-setup-to-install-iis-70/
      end
      
    else
      puts 'PFTT: host_config: ensuring GCC toolchain installed...'
      linux_install(host, "autoconf")
      linux_install(host, "make")
      linux_install(host, "gcc")
      puts 'PFTT: host_config: ensuring Apache installed...'
      linux_install(host, "apache-httpd")
    end
    #
    # TODO install svn
  end
  def update_config
    puts 'PFTT: updating configuration from server...'
    # TODO update_config
  end
  def scenario_config
    # LATER scenario config
  end
  if CONFIG[:action] == 'func_list'
    # write list of selected tests to file
    
    $testcases = CONFIG.selected_tests(false, false).flatten
    
    f = File.open(CONFIG[:test_list_file], 'wb')
     
    arw = ArgRewriter.new(ARGV)
    arw.cmd('func_part')
    arw.remove('--tests')
      
    # demonstrate that user can use # to cause lines in file to be ignored
    # also store command line so user can copy and paste it to run this list of tests
    f.puts("#\r")
    f.puts("# run the line below to run the list of tests in this file: \r")
    f.puts("# #{arw.join}\r")
    f.puts("#\r")
    
    $testcases.each{|test_case| f.puts("#{test_case.full_name}\r")}
      
    f.close
      
    exit
  elsif CONFIG[:action] == 'func_full' or CONFIG[:action] == 'func_part' 
    # func_full - run all PHPTs (always deploy php build and test cases too)
    # func_part - run selected PHPTs (deploy php build and/or test cases if modified)
    
    #
    if $debug_test
      # ensure host(s) have a debugging tool installed
      missing_debugger = false
      $hosts.map{|host|
          puts "PFTT: checking #{host} for a debugger..."
          unless host.has_debugger?
            missing_debugger = true
            if host.windows?
              puts "PFTT: error: install Debugging Tools For Windows (x86) on #{host}"
            else
              puts "PFTT: error: install GDB on #{host}"
            end
          end
        }
      if missing_debugger
        puts "PFTT: to continue with --debug, install debugger(s) on listed host(s)"
        puts
        exit(-5)
      else
        puts "PFTT: host(s) have debuggers, continuing..."
      end
    end
    #
    
    $testcases = CONFIG.selected_tests()
    
    #
    #
    $thread_pool_size = $thread_pool_size * $hosts.length
    if $thread_pool_size > 60
      $thread_pool_size = 60
    end
    #
    
    # stop Forefront Endpoint Protection and windows search service/indexer
    #  this will speed up deployment and test runtime by 15-30%
    hosts_to_restore = []
    test_ctx = nil
    begin
      if CONFIG[:action] == 'func_full'
        $hosts.each{|host|
          if host.windows?
            host.exec!('elevate net stop wsearch')
            host.exec!('elevate TASKKILL /IM MsMpEng.exe')
            hosts_to_restore.push(host)
          end
        }
      end
    
      require 'time'
    
      start_time = Time.now()
      begin
        # lock hosts with PFTT Server (if available) so they aren't used by two PFTT clients at same time
        lock_all($hosts)
    
        # if func_full automatically do host configuration
        if CONFIG[:action] == 'func_full'
          host_config
        end
        
        test_bench = TestBench::Phpt.new($phps, $hosts, $middlewares[0], $scenarios) # TODO
      
        # TODO print telemetry folder before starting (so user can read telemetry in real time)
        
        # finally do the testing...
        # iterate over all hosts, middlewares, etc..., running all tests for each
        test_ctx = test_bench.iterate( $phps, $hosts, $middlewares, $scenarios, $testcases ) # TODO

      ensure
        # ensure hosts are unlocked
        release_all($hosts)
      
      end
      end_time = Time.now()
      run_time = end_time - start_time
    
    ensure
      if CONFIG[:action] == 'func_full'
        # restart wsearch on hosts where it was already running (also, restart MsMpEng.exe)
        hosts_to_restore.each{|host|
          if host.windows?
            host.exec!('elevate net start wsearch')
            host.exec!('msmpeng')
          end
        }
        #
      end
    end
    
    ########## done testing, collect/store results, report and cleanup #############
    
    
    #
    # generate EXT_RUN.list file in telemetry folder EXT_ALL.list EXT_SKIP.list
    #    include command line that will run those exact extensions with func_part
#    def write_ext_file(ext_list, file_name)
#      ext_file = File.join(test_ctx.telemetry_folder, file_name)
#      arw = ArgRewriter(ARGV)
#      arw.cmd('func_part')
#      arw.replace('--test-list', ext_run_file)
#    
#      f = File.open(ext_file, 'wb')
#      f.puts('#')
#      f.puts('#')
#      f.puts('# '+arw.join())
#      f.puts('#')
#      ext_list.each{|ext_name| f.puts(ext_name+"\r\n") }
#      f.close()
#    end
#    write_ext_file(r.ext(:run), 'EXT_RUN.list')
#    write_ext_file(r.ext(:all), 'EXT_ALL.list')
#    write_ext_file(r.ext(:skip), 'EXT_SKIP.list')
#    #
#    
#    # store list of scenarios in telemetry folder
#    scn_file = File.open(File.join(test_ctx.telemetry_folder, 'scenarios.list'), 'wb')
#    # TODO scenarios.each{|ctx| ctx_file.puts(ctx.ctx_name+"\r\n") }
#    scn_file.close()
#    #
#    
#    r = test_ctx.results
#    # display summary of results
#    puts
#    puts

    # test bench would have already done a summary for this one host/middleware so don't need to repeat it
    unless $hosts.length == 1 and $middlewares.length == 1 and ( $brief_output or CONFIG[:action] == 'func_part' )
      # for func_part user shouldn't have to take time navigating through a redudant report
      # to get to the telemetry they need
      report = Report::Run::ByHost::Func.new()
      report.text_print()
    end
    
# TODO    if $html_report
#      filename = $hosts[0].mktmpfile("report.html")
#      report.html_file(filename)
#      $hosts[0].exec("start \"#{filename}\"")
#    end
     
    exit
  elsif CONFIG[:action] == 'func_inspect'
    # inspects what the configuration and arguments will have pftt do for the func_full or func_part actions
    # (lists PHPTs that will be run, hosts, middlewares, php builds and contexts)
    
    report = Report::Inspect::Func.new()
    report.text_print()
    
    exit
  elsif CONFIG[:action] == 'hc'
    host_config()
    exit
  elsif CONFIG[:action] == 'cs'
    scenario_config
  elsif CONFIG[:action] == 'perf'
    # LATER implement performance testing
    # 
    # -if comparing performance between two versions, raise warning if performance difference is greater than 25%
    #    -remind user to check disk free
    # -get web page size (before start) and compare to average web page size
    # -get web page several times during run and store copies of it
    #    -especially if there is an error code
    # 
    # LATER run ui test periodically during performance test
    puts "PFTT: error: performance testing not implemented"
    exit(1)
  elsif CONFIG[:action] == 'stress'
    # LATER implement stress testing
    # LATER run ui test periodically during stress test
    puts "PFTT: error: stress testing not implemented"
    exit(1)
  elsif CONFIG[:action] == 'unit'
    # LATER implement unit test support (run unit tests supplied with applications like mediawiki)
    puts "PFTT: error: PHPUnit support not implemented"
    exit(1)
  elsif CONFIG[:action] == 'ui'
    # LATER implement selenium support
    # mediawiki, joomla, drupal all have selenium frameworks
    # wordpress may have a selenium framework (not sure)
    puts "PFTT: error: app compat support not implemented"
    exit(1)
  #elsif CONFIG[:action] == 'fuzz_cmp'
    # LATER? run same fuzz test on two+ hosts and compare the results
    # useful for detecting weird behavior, like unlink() trimming trailing whitespace
  elsif CONFIG[:action] == 'update_config'
    unless $client
      puts 'PFTT: error: not available: this PFTT client has not been set to use a specific PFTT server'
      puts 'PFTT: update_config action requires a PFTT server. '
      puts
      exit(-12)
    end
    
    update_config
    exit
  elsif CONFIG[:action] == 'upgrade'
    puts 'PFTT: upgrading PFTT'
    puts 'PFTT: downloading changes'
    exec("git pull")
    update_config
    puts 'PFTT: running installation script'
    exec("rake install")
    puts
    puts 'PFTT: upgrade complete. newest version installed to #{__DIR__}'
    puts
  elsif CONFIG[:action] == 'net_lock'
    unless $client
      puts 'PFTT: error: not available: this PFTT client has not been set to use a specific PFTT server'
      puts 'PFTT: net_lock action requires a PFTT server. '
      puts
      exit(-12)
    end
    
    CONFIG[:target_host_name].each{|host_name|
      $client.net_lock(host_name)
      puts "PFTT: locked #{host_name}"
    }
    puts
    
  elsif CONFIG[:action] == 'net_release'
    unless $client
      puts 'PFTT: error: not available: this PFTT client has not been set to use a specific PFTT server'
      puts 'PFTT: net_release action requires a PFTT server. '
      puts
      exit(-12)
    end
      
    CONFIG[:target_host_name].each{|host_name|
      $client.net_release(host_name)
      puts "PFTT: released #{host_name}"
    }
    puts
    
  elsif CONFIG[:action] == 'net_view'
    unless $client
      puts 'PFTT: error: not available: this PFTT client has not been set to use a specific PFTT server'
      puts 'PFTT: net_view action requires a PFTT server. '
      puts
      exit(-12)
    end
    
    report = Report::Network.new()
    report.text_print()
    
    puts   
  end
end
