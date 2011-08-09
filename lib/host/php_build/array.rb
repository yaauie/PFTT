require 'typed-array'

class PhpBuild
  class Array < Array
    extend TypedArray
    restrict_types Host::Base

    include FilterByPropertyValue
    
    # provide a method for loading more using filesystem globs
    def load(*globs)
      globs.each do |glob|
        Dir.glob( glob ) do |php|
          self << PhpBuild.new( php )
        end
      end
    end
  end
end