module TestBench
  class Base
    def initialize( php_build, host, middleware, *contexts )
      @php = php_build
      @host = host
      @middleware = middleware.new( host, php, *contexts )
      @contexts = contexts # an array of arrays, each of which contains one type
    end

    attr_reader :php, :host, :middleware, :contexts

    # 
    # Test each of the supplied factors to see if they are compatible with the others.
    # This is a little tricky, as incompatibility is not necessarily two-way.
    # 
    # See TestBenchFactor::compatible? for conventions on how these are defined.
    # 
    def compatible?
      catch(:compatibility) do
        [php,host,middleware,*contexts].permutation(2) do |factor1,factor2|
          throw :compatibility, false unless factor1.meets_requirements_of? factor2
        end
        throw :compatibility, true
      end
    end

    attr_reader :php, :host, :middleware

    # pass calls to the TestBench to the associated Middleware with PhpBuild and Host
    # as prepended arguments.
    #
    # this ->    test_bench.call_script( )
    # 
    # becomes -> (test_bench.middleware).call_script( (test_bench.php), (test_bench.host), 'foo.php' )
    #
    [
      :install,
      :uninstall,
      :apply_ini,
      :call_script,
    ].compact.each do |method_name|
      define_method method_name do |*args,&block|
        return @middleware.method(method_name).call( *args, &block )
      end
    end

    def describe
      @description ||= [
        %Q{#{@php.properties[:version]}-#{DateTime.now.strftime('%Y%m%d-%H%M%S')}},
        @middleware.describe,
        @host.describe,
        @php.describe
      ].compact
    end

    class << self
      # TestBench.iterate( php_builds, hosts, middlewares, *args ){|*args| &block }
      # 
      # First three arguments must be TypedArray instances carrying collections of 
      #  instances of PhpBuild, Host, and Middleware respectively. 
      # 
      # For each unique combination of PhpBuild, Host, and Middleware (all of which
      # include TestBenchFactor), if the TestBenchFactors are compatible with each 
      # other, the block is executed with the remaining arguments and its value is
      # appended to the results array.
      # 
      # 
      # 
      def iterate( *factors, test_cases )
        results = self.results_array.new()
        factors.shift.product *factors do |php,host,middleware,*contexts|
          puts ({:php=>php,:host=>host,:middleware=>middleware,:contexts => contexts}.inspect)
          begin
            test_bench = self.new( php, host, middleware, *contexts )
            
            #skip this test bench if its components are not compatible.
            next unless test_bench.compatible?

            test_bench.install
            puts test_bench.describe.join(' ')
            
            results.concat test_bench.run test_cases
          #ensure
            test_bench.uninstall
          end
        end
        results
      end
    end
  end
end