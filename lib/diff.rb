require 'abstract_class'
module Diff
  class Base
    abstract
    def initialize( expected, actual )
      @expected = expected
      @actual = actual
    end

    def to_s
      @s ||= diff.map do |line|
        case line[0]
        when :insert then '+'
        when :delete then '-'
        else ''
        end + line[1].gsub(/\n\Z/,'')
      end.join("\n")
    end

    def stat
      {
        :inserts=>0,
        :deletes=>0
      }
    end

    def match?
      @match ||= changes.zero?
    end

    def changes
      @changes ||= diff.count{|token| next true unless token[0]==:equals}
    end

    protected

    def diff
      @diff ||= _get_diff( 
        @expected.lines.map{|i|i}, # we want to keep the separator
        @actual.lines.map{|i|i}    # so we can't just split
      )
    end

    private

    # This method gets replaced by sub-classes and is the part that does the actual
    # comparrisons.
    def _compare_line( expectation, result )
      expectation == result
    end

    def _get_diff( expectation, result )
      prefix = _common_prefix( expectation, result )
      if prefix.length.nonzero?
        expectation.shift prefix.length
        result.shift prefix.length
      end

      suffix = _common_suffix( expectation, result )
      if suffix.length.nonzero?
        expectation.pop suffix.length
        result.pop suffix.length
      end

      return (
        _tokenize( prefix, :equals ) +
        _diff_engine( expectation, result )+
        _tokenize( suffix, :equals )
      )
    end

    def _diff_engine( expectation, result )
      
      return _tokenize( result, :insert ) if expectation.empty?
      return _tokenize( expectation, :delete ) if result.empty?

      case
      when expectation.length < result.length
        # test to see if the expectation is *inside* the result
        start = 0
        while start+expectation.length <= result.length
          return(
            _tokenize( result.first( start ), :insert ) +
            _tokenize( result.slice( start, expectation.length ), :equals )
            _tokenize( result.dup.drop( start + expectation.length  ), :insert )
          ) if _compare_lines( expectation, result.slice( start, expectation.length ) )
          start +=1
        end
      when result.length < expectation.length 
        # test to see if the result is *inside* the expectation
        start = 0
        while start+result.length <= expectation.length
          return(
            _tokenize( expectation.first( start ), :insert ) +
            _tokenize( result, :equals )
            _tokenize( expectation.dup.drop( start + result.length  ), :insert )
          ) if _compare_lines( expectation.slice( start, result.length ), result )
          start +=1
        end
      end
      
      lcs_max = 500
      chunk_size = 50

      if (expectation.length + result.length) < lcs_max
        # try using LCS
        _diff_lcs( expectation, result)
      elsif [expectation.length,result.length].min > chunk_size
        # chunk off a bit & try again
        _reduce_noise(
          _get_diff( expectation.first(chunk_size), result.first(chunk_size) )+
          _get_diff( expectation.dup.drop(chunk_size), result.dup.drop(chunk_size) )
        )
      else
         # last resort.
        _tokenize( expectation, :delete ) + _tokenize( result, :insert )
      end
    end

    def _diff_lcs( expectation, result )
      #Build the LCS tables
      common = Array.new( expectation.length+1 ).map! {|item| Array.new( result.length+1 ) }
      lcslen = Array.new( expectation.length+1 ).map! {|item| Array.new( result.length+1, 0 ) }
      expectation.each_index do |a|
        result.each_index do |b|
          common[a+1][b+1]= _compare_line( expectation[a], result[b] )
          lcslen[a+1][b+1] = ( common[a+1][b+1] ? lcslen[a][b] + 1 : [ lcslen[a][b-1], lcslen[a-1][b] ].max )
        end
      end

      # Transverse those tables to build the diff
      cursor = {:a=>expectation.length,:b=>result.length}
      diff = [];
      while cursor.values.max > 0
        case
        when cursor[:a]>0 && cursor[:b]>0 && common[cursor[:a]][cursor[:b]]
          diff.unshift [:equals,result[cursor[:b]-1]]
          cursor[:a]-=1 # Move left
          cursor[:b]-=1 # Move up
        when cursor[:b]>0 && (cursor[:a].zero? || lcslen[cursor[:a]][cursor[:b]-1] >= lcslen[cursor[:a]-1][cursor[:b]])
          diff.unshift [:insert,result[cursor[:b]-1]]
          cursor[:b]-=1 # Move up
        when cursor[:a]>0 && (cursor[:b].zero? || lcslen[cursor[:a]][cursor[:b]-1] < lcslen[cursor[:a]-1][cursor[:b]])
          diff.unshift [:delete,expectation[cursor[:a]-1]]
          cursor[:a]-=1 # Move left
        end
      end
      diff
    end

    def _reduce_noise( diff )
      return diff if diff.length.zero?

      ret = []
      cache = Hash.new{|h,k|h[k]=[]}

      diff.each do |token|
        case token[0]
        when :equals
          [:insert,:delete].each do |action|
            (cache.delete(action)||[]).each do |token|
              ret.push token
            end
          end
          ret.push token
        else
          puts %Q{pushing: [#{token[0]}] #{token.inspect}}
          cache[token[0]].push token
        end
      end

      puts ret.inspect

      ret
    end

    # if the first diff has a bunch of deletes at the end that match inserts at the beginning of the second diff
    # or inserts in at the tail of the 1st that match deletes at the head of the 2nd, 
    def _concatenate_diffs( first_half, second_half )

    end

    def _compare_lines( expectation, result )
      return false unless expectation.length == result.length
      expectation.zip(result).each do |ex, re|
        return false unless _compare_line( ex, re )
      end
      return true
    end

    def _tokenize(ary,token)
      ary.map do |item|
        [token,item]
      end
    end

    def _common_prefix( expectation, result )
      prefix = []
      k=0
      while k < expectation.length
        return prefix if !_compare_line( expectation[k], result[k] )
        prefix.push result[k]
        k+=1
      end
      prefix
    end

    def _common_suffix expectation, result
      _common_prefix( expectation.reverse, result.reverse ).reverse
    end
    
  end

  class Exact < Base
    def _compare_line( expectation, result )
      expectation == result
    end
  end

  class RegExp < Base
    def _compare_line( expectation, result )
      #puts %Q{compare: #{expectation.inspect} to #{result.inspect}}
      Regexp.new(%Q{\\A#{expectation}\\Z}).match(result)
    end
  end

  class Formatted < RegExp
    # Provide some setup for inheritance. Really I should come up with a way
    # to abstract this, but yet another implementation will have to work for now.
    class << self
      def patterns arg=nil
        case when arg.nil? #getting with inheritance
          compiled = {}
          ancestors.to_a.reverse_each do |ancestor|
            next true unless ancestor.respond_to? :patterns
            compiled.merge! ancestor.patterns(false)
          end
          compiled
        when arg==false # getting without inheritance
          @patterns ||= {}
        else # setting
          (@patterns||={}).merge! arg
        end
      end
    end
    def patterns arg={}
      (@patterns ||= {}).merge! arg
      self.class.patterns.merge( @patterns )
    end

    protected

    #ok, now for the implementation:
    def _compare_line( expectation, result )
      rex = Regexp.escape(expectation)
      # arrange the patterns in longest-to shortest and apply them.
      # the order matters because %string% must be replaced before %s.
      patterns.to_a.sort{|a,b|-1*(a[0].size <=> b[0].size)}.each{|pattern| rex.gsub!(pattern[0], pattern[1])}
      super( rex, result )
    end

    # and some default patterns
    patterns ({
      '%e' => '\\[\\/]',# a little too fogiving since I don't know which host it's running on.
      '%s' => '[^\r\n]+',
      '%S' => '[^\r\n]*',
      '%a' => '.+',
      '%A' => '.*',
      '%w' => '\s*',
      '%i' => '[+-]?\d+',
      '%d' => '\d+',
      '%x' => '[0-9a-fA-F]+',
      '%f' => '[+-]?\.?\d+\.?\d*(?:[Ee][+-]?\d+)?',
      '%c' => '.',
    })

    class Php5 < Formatted
      patterns ({
        '%u\|b%' => '',
        '%b\|%u' => '', #PHP6+: 'u'
        '%binary_string_optional%' => 'string', #PHP6+: 'binary_string'
        '%unicode_string_optional%' => 'string', #PHP6+: 'Unicode string'
        '%unicode\|string%' => 'string', #PHP6+: 'unicode'
        '%string\|unicode%' =>  'string', #PHP6+: 'unicode'
      })
    end
    class Php6 < Formatted
      patterns ({
        '%u\|b%' => 'u',
        '%b\|%u' => 'u', #PHP6+: 'u'
        '%binary_string_optional%' => 'binary_string', #PHP6+: 'binary_string'
        '%unicode_string_optional%' => 'Unicode string', #PHP6+: 'Unicode string'
        '%unicode\|string%' => 'unicode', #PHP6+: 'unicode'
        '%string\|unicode%' =>  'unicode', #PHP6+: 'unicode'
      })
    end
  end
end
