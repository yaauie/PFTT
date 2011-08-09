module TestBenchFactor
  def results
    @_results ||= TestResultArray.new
  end

  def attach_result result
    results << result
  end

  # Incompatibilities are generally go both ways. 
  # In order to DRY logic, the order these should be defined in the order of the stack.
  # 
  # PhpBuild    # issues with MW or H or ( MW and H )
  # Middleware  # issues with H or ( PB and H )
  # Host        # issues with ( PB and M )
  #
  # For example, if a  
  def compatible_with? other_test_bench_factor
    return true
  end
end