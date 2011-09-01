module PhptTestResult
  class Base
    def initialize( test_case, test_bench )
      @test_case = test_case
      @test_bench = test_bench
      files['phpt'] = @test_case.raw
      self
    end

    attr_reader :test_case, :test_bench
    attr_accessor :status

    def to_s
      %Q{[#{status.to_s.upcase}] #{@test_bench} #{@test_case.relative_path}}
    end

    def save
      base_path = File.join((%Q{#{APPROOT}/results}),*test_bench.describe)
      FileUtils.mkdir_p base_path
      File.open( File.join( base_path, %Q{#{status.to_s.upcase}.list} ), 'a' ) do |file|
        file.write test_case.relative_path + "\n"
      end
      specific = File.join( base_path, File.dirname( test_case.relative_path ) )
      FileUtils.mkdir_p specific
      files.each_pair do |extension, contents|
        File.open( File.join( specific, %Q{#{test_case.name}.#{extension}}),'w') do |file|
          file.write contents
        end
      end
    end

    private

    def files # { '.php' => 'contents of the file' }
      @files ||= {}    
    end
  end

  class Skip < Base
    def initialize *args, reason
      super *args
      self.status = :skip
      @reason = reason
      files['.skipif.php'] = @test_case[:skipif]
      files['.skipif.result'] = @reason
      self
    end

    def to_s
      %Q{#{super}\n  #{@reason}}
    end
  end

  class Bork < Skip
    def initialize test_case, test_bench
      super test_case, test_bench, test_case.bork_reasons
      self.status = :bork
      files.delete('skipif.php')# TODO fix inheritance so we don't need to do this
      files.delete('skipif.result')
      self
    end
  end

  class Unsupported < Skip
    def initialize test_case, test_bench
      super test_case, test_bench, 'unsupported sections:'+test_case.unsupported_sections.join(',')
      self.status = :todo
      files.delete('skipif.php') # TODO fix inheritance so we don't need to do this
      files.delete('skipif.result')
      self
    end
  end

  class Meaningful < Base
    def initialize *args, result_str
      super *args

      @filtered_expectation, @filtered_result = [@test_case.expectation[:content], result_str].map do |str|
        str.gsub("\r\n","\n").strip
      end

      @diff = (case @test_case.expectation[:type]
      when :expect then Diff::Exact
      when :expectregex then Diff::Exact
      when :expectf
        case @test_bench.php.properties[:php_version_major]
        when 5 then Diff::Formatted::Php5
        when 6 then Diff::Formatted::Php6
        else Diff::Formatted
        end
      end).new( @filtered_expectation, @filtered_result )

      self.extend (case [ !@test_case.has_section?(:xfail), @diff.changes.zero? ]
      when [true, true] then Pass # was expected to pass and did
      when [true, false] then Fail # was expected to pass and did not
      when [false, true] then XFail::Works # was expected to fail and passed
      when [false, false] then XFail::Fail # was expected to fail and failed
      end)

      files['php'] = test_case[:file]
      files['result'] = result_str

      files['diff']=@diff.to_s unless @diff.changes.zero?

      self
    end
  end

  # we need to be able to mix these in after running the actual test scenario
  module Pass
    def self.extended(base)
      base.status = :pass
    end
  end

  module Fail
    def self.extended(base)
      base.status = :fail
    end
    def to_s
      <<-END
#{super}
--#{@test_case.expectation[:type].upcase}--
#{@filtered_expectation}
--ACTUAL--
#{@filtered_result}
--DIFF--
#{@diff.to_s.split("\n").map{|l|'  |'+l}.join("\n")}
----------
      END
    end
  end

  class Array < TypedArray(PhptTestResult::Base)

    def pass
      generate_stats[:pass]
    end

    def fail
      generate_stats[:fail]
    end

    def rate
      return 'NA' if (fail+pass).zero?
      pass * 100 / (fail + pass) 
    end

    private 

    def generate_stats
      @counts = Hash.new(0)
      self.each do |result|
        @counts[result.status]||=0
        @counts[result.status]+=1
      end
      @counts
    end
  end

  module XFail
    module Pass
      def self.extended base
        base.status = :xfail
      end
    end

    module Works
      def self.extended base
        base.status = :works
      end
    end
  end
end