module TestBench
  class Phpt < Base
    def run(test_cases)
      results = self.results_array.new()

      test_cases.map do |test_case|
        test = test_case.dup
        # return early if this test case is not supported or is borked
        case
        when test.borked? then next TestResult::Bork.new( test, self )
        when test.unsupported? then next TestResult::Unsupported.new( test, self )
        end

        begin
          @middleware.apply_ini test[:ini] # ideal place for multithreading if @host.exec is threadsafe.
          test.expand
          deployed = Hash.new
          test.files.each_pair do |key,local_item|
            deployed[key] = Host::Local.deploy( local_item ).to(@host, @middleware.docroot )
          end

          # catch the result here
          result = catch(:result) do
            # if a skipif section is present, see if we should skip this test
            unless test_case[:skipif].nil?
              skipif = @middleware.execute_php_script deployed[:skipif]
              throw( :result, TestResult::Skip, skipif ) if skipif.downcase.start_with? 'skip'
            end

            begin
              # we did not skip the test, run it.
              test.attach_result( @middleware.execute_php_script( deployed[:file] ) )
              throw( :result, TestResult::Pass ) if test.pass?
              throw( :result, TestResult::Fail )
            ensure
              # and clean up if we are supposed to
              unless test_case[:clean].nil? or CONFIG[:skip_cleanup]
                @middleware.execute_php_script deployed[:clean]
              end
            end
          end

          # take the caught result and build the proper object out of it
          next result.shift.new( test, self, *result )
        ensure
          Host::Local.delete test.files.values
          @host.delete deployed.values.flatten unless CONFIG[:skip_cleanup]
        end
      end
      results
    end
  end
end