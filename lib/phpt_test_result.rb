module PhptTestResult
  class Base
    def initialize( test_case, test_bench )
      @test_case = test_case
      @test_bench = test_bench
      self
    end

    attr_accessor :status

    def to_s
      %Q{[#{status.to_s.upcase}] #{@test_bench} #{@test_case.name}}
    end
  end

  class Skip < Base
    def initialize *args, reason
      super *args
      self.status = :skip
      @reason = reason
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
      self
    end
  end

  class Unsupported < Skip
    def initialize test_case, test_bench
      super test_case, test_bench, 'unsupported sections:'+test_case.unsupported_sections.join(',')
      self.status = :todo
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
        case @test_bench.php.properties[:version_major]
        when 5 then Diff::Formatted::Php5
        when 6 then Diff::Formatted::Php6
        else Diff::Formatted
        end
      end).new( @filtered_expectation, @filtered_result )

      if @diff.changes.zero?
        self.extend Pass
      else
        self.extend Fail
      end
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
----DIFF----
#{@diff.to_s.split("\n").map{|l|'  |'+l}.join("\n")}
--EXPECTED--
#{@filtered_expectation}
---ACTUAL---
#{@filtered_result}
------------
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
end