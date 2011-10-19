
module Report
  module Comparison
    module ByPlatform # TODO rename to ByOS
      class Base < Base
        def resultsets_by_platform
          return [{:a=>'', :b=>'', :platform=>'', :arch=>''}, {:a=>'', :b=>'', :platform=>'', :arch=>''}]
        end
      end
    end
  end
end
