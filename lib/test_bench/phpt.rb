module TestBench
  class Phpt < Base
    class << self
      def results_array
        PhptTestResult::Array
      end
    end

    #helper method. perhaps find a better place to put this.
    def deploy_phpt_section( test_case, section)
      deployed_location = File.join(@middleware.docroot, %Q{#{test_case.name}.#{test_case.extension[section]}})
      @host.delete(deployed_location) if @host.exist?(deployed_location)
      @host.open_file(deployed_location,'w') do |f|
        f.write test_case[section]
        f.close
      end

      deployed_location
    end

    def run(test_cases)
      results = self.class.results_array.new()
      deployed = {}
      test_cases.map do |test_case|
        test = test_case
        # catch the result here
        result_spec = catch(:result) do
          # return early if this test case is not supported or is borked
          case
          when test.borked? then throw :result, [PhptTestResult::Bork]
          when test.unsupported? then throw :result, [PhptTestResult::Unsupported]
          end

          begin
            @middleware.apply_ini test[:ini] # ideal place for multithreading if @host.exec is threadsafe.

            # if a skipif section is present, see if we should skip this test
            unless test[:skipif].nil?
              deployed[:skipif] = deploy_phpt_section test, :skipif
              skipif = @middleware.execute_php_script(deployed[:skipif])[1]
              if skipif.downcase.start_with? 'skip'
                throw :result, [PhptTestResult::Skip, skipif]
              end
            end

            begin
              # we did not skip the test, run it.
              deployed[:file] = deploy_phpt_section test, :file
              throw :result, [PhptTestResult::Meaningful, @middleware.execute_php_script( deployed[:file] )[1]]
            ensure
              # and clean up if we are supposed to
              unless test_case[:clean].nil? or CONFIG[:skip_cleanup]
                deployed[:clean] = deploy_phpt_section test, :clean
                @middleware.execute_php_script deployed[:clean]
              end
            end

          ensure
            @host.delete deployed.values.flatten unless CONFIG[:skip_cleanup]
          end
        end
        # take the caught result and build the proper object out of it
        result = result_spec.shift.new( test, self, *result_spec )
        puts result.to_s
        results << result
      end
      results
    end
  end
end
