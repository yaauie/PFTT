module Context
  module FileSystem
    class Base
      def up
        middleware.docroot = :default
      end

      def down
        # nothing to do.
      end
    end

    All = (Class.new(TypedArray( Class )){include TestBenchFactorArray}).new #awkward, but it works.
  end
end