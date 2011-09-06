module TestBench
  class Phpt < Base
    class << self
      def results_array
        PhptTestResult::Array
      end
    end

    def save_dir
      File.join(
        %{#{@php.properties[:version]}-#{String.random(12)}}
      )
    end

    #helper method. perhaps find a better place to put this.
    def deploy_phpt_section( test_case, section )
      deployed_location = File.join(@host.cwd, %Q{#{test_case.name}.#{test_case.extension[section]}})
      @host.delete(deployed_location) if @host.exist?(deployed_location)
      @host.open_file(deployed_location,'w') do |f|
        f.write test_case[section]
        f.close
      end

      deployed_location
    end

    def run(test_case_sets)
      test_case_sets.map do |test_cases|
        tmpdir = @host.mktmpdir(@middleware.docroot)

        # parse all the phpt's and upload the files at the same time.
        threads = []
        threads.push Thread.start{ puts 'uploading';@host.upload test_cases.path, tmpdir; puts 'uploaded.' }
        threads.push Thread.start{ puts 'loading'; test_cases.load; puts 'loaded' }
        threads.each {|thread| thread.join }

        results = self.class.results_array.new()
        deployed = {}
        test_cases.map do |test_case|

          @host.pushd File.join( 
            tmpdir, 
            File.basename( test_cases.path ), 
            File.dirname( test_case.relative_path )
          )
          #puts 'cwd: '+@host.cwd
          
          test = test_case
          puts "[    ] #{test.relative_path}"
          # catch the result here
          result_spec = catch(:result) do
            # return early if this test case is not supported or is borked
            case
            when test.borked? then throw :result, [PhptTestResult::Bork]
            when test.unsupported? then throw :result, [PhptTestResult::Unsupported]
            end

            begin

              @middleware.apply_ini test.ini.to_a.map{|i|i.gsub('{PWD}',@host.cwd)} # ideal place for multithreading if @host.exec is threadsafe.
              #puts '--INI--'
              #puts test.ini.to_a.map{|i|i.gsub('{PWD}',tmpdir)}

              # if a skipif section is present, see if we should skip this test
              unless test[:skipif].nil?
                deployed[:skipif] = deploy_phpt_section test, :skipif
                skipif = @middleware.execute_php_script(deployed[:skipif])[1]
                #puts '--SKIPIF--'
                #puts test[:skipif]
                if skipif.downcase.start_with? 'skip'
                  throw :result, [PhptTestResult::Skip, skipif]
                end
                #puts '--SKIPIF-OUT--'
                #puts skipif
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
              deployed.values.flatten.each do |deployed_file|
                @host.delete deployed_file
              end
            end
          end

          @host.popd

          # take the caught result and build the proper object out of it
          result = result_spec.shift.new( test, self, *result_spec )
          puts result.to_s
          result.save
          results << result
        end
        @host.delete tmpdir
        results
      end
    end
  end
end
