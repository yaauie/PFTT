#bootstrap.rb
require 'active_support/dependencies'

APPROOT = File.absolute_path( File.dirname( __FILE__ ) ) 
libdir = File.join( APPROOT, 'lib' )
ActiveSupport::Dependencies.autoload_paths << libdir
$: << libdir


require 'optparse'
require 'pp'

class PfttOptions
  
  def self.parse(args)
    default_config_file = "#{APPROOT}/config/default.yaml"
    puts default_config_file
    puts File.exists? default_config_file
    options = OptionsHash.new
    #puts YAML::load( default_config_file ).inspect
    options.replace(YAML::load( File.open(default_config_file) )) unless !File.exists?( default_config_file )
    puts options.inspect
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options]"

      opts.separator ''
      opts.separator 'Specific Options:'

      opts.on(
        '--func[tional]',
        'Run functional tests with configuration'
      ) do
        options[:action] = :functional
      end

      opts.on(
        '--perf[ormance]',
        'Run performance tests with configuration'
      ) do
        options[:action] = :functional
      end

      opts.on(
        '--inspect',
        'Inspect objects loaded by configuration'
      ) do
        options[:action] ||= :inspect
        options[:inspect] = true
      end

      opts.on(
        '--clear',
        'Clear the loaded configuration entirely. Helpful for scenarios in which you do not want to use the default configuration, or want to clear out a particular setting.'
      ) do
        options.clear
      end

      opts.on( 
        '-c', 
        '--config <FILE>', 
        'Load a .yml config file into the current options'
      ) do |config|
        options.merge! YAML::load( config )
      end

      opts.on( 
        '--php-dir DIRECTORY', 
        'set the directory in which to look for php builds'
      ) do |php_dir|
        options[:php,:dir] = php_dir
      end

      opts.on( 
        '--php-compiler <COMPILER>[,<COMPILER>[,...]]', 
        Array, 
        'Only include PHP Builds whose compiler matches'
      ) do |php_compilers|
        options[:php,:filters,:compiler]||= []
        options[:php,:filters,:compiler].concat php_compilers
      end

      opts.on( 
        '--php-version <PHPVERSION>[,<PHP_VERSION>]',
        Array
      ) do |php_versions|
        options[:php,:filters,:version]||= []
        options[:php,:filters,:version].concat php_versions
      end

      opts.on( 
        '--platform <PLATOFRM>[,<PLATFORM>]',
        Array
      ) do |platforms|
        options[:php,:filters,:platform]||= []
        options[:php,:filters,:platform].concat platforms
      end

      opts.on( 
        '--hosts <HOST>[,<HOST>[,...]]',
        Array
      ) do |hosts|
        options[:hosts]||=[]
        options[:hosts].concat hosts
      end

      opts.on( 
        '--middleware <MIDDLEWARE>[,<MIDDLEWARE>[,...]]',
        Array
      ) do |middlewares|
        options[:middleware]||=[]
        options[:middleware].concat middlewares
      end

      opts.on(
        '--context-fs <CONTEXT>[,<CONTEXT>[,...]]',
        Array
      ) do |fs_context|
        options[:contexts,:fs,:filters]||=[]
        options[:contexts,:fs,:filters] << {:name => fs_context }
      end

      opts.on( 
        '--phpt-tests <glob>[,<glob>[,...]]',
        Array
      ) do |test_globs|
        options[:phpt]||=[]
        options[:phpt].concat test_globs
      end

      opts.on_tail(
        "-h", "--help", 
        "Show this message"
      ) do
        puts opts
        exit
      end
    end

    opts.parse! args
    options
  end
end

# parse in the options
CONFIG = PfttOptions.parse ARGV

# set up our basic test bench factors
$hosts = (Host::All).filter(CONFIG[:host,:filters])
require 'typed-array'
$phps = PhpBuild.get_set(CONFIG[:php,:dir]||'').filter(CONFIG[:phps,:filters])
$middlewares = Middleware::All.filter(CONFIG[:middleware,:filters])
$fs_contexts = Context::Filesystem::All.filter(CONFIG[:context,:filesystem,:filters])
$cache_contexts = Context::Filesystem::All.filter(CONFIG[:context,:cache,:filters])

case CONFIG[:action].to_s
when 'functional'
  $testcases = Phpt::TestCase::Array.new.load(CONFIG[:phpt])
  require 'bin/functional.rb'
when 'inspect'
  puts $hosts
  puts $phps
  puts $middlewares
else
  puts 'An action must be specified: --func[tional] --perf[ormance]'
  exit
end
