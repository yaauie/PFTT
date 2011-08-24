module TestBench
  class Base
    def initialize( php_build, host, middleware )
      @php = php_build
      @host = host
      @middleware = middleware
    end

    # 
    # Test each of the supplied factors to see if they are compatible with the others.
    # This is a little tricky, as incompatibility is not necessarily two-way.
    # 
    # See TestBenchFactor::compatible? for conventions on how these are defined.
    # 
    def compatible?
      catch(:compatibility) do
        [php,host,middleware].permutation(2) do |factor1,factor2|
          throw :compatibility false unless factor1.meets_requirements? factor2
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
      :install!,
      :uninstall!,
      :apply_ini,
      :call_script,
    ].compact.each do |method_name|
      define_method method_name do |*args,&block|
        return middleware.method(method_name).call( php, host, *args, &block )
      end
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
      def iterate( *args, &block )
        php_builds, hosts, middlewares = args.shift(3)
        results = []
        php_builds.product hosts, middlewares do |php,host,middleware|
          begin
            test_bench = TestBench.new( php, host, middleware )
            
            #skip this test bench if its components are not compatible.
            next unless test_bench.compatible?
            
            test_bench.install!

            result = (yield *args)
            results << result unless result.nil?
          ensure
            test_bench.uninstall!
          end
        end
        results
      end
    end
  end
end