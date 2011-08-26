module Context
  module Cache
    class Base
      def up
        # nothing to do.
      end

      def down
        # nothing to do.
      end
    end

    All = (Class.new(TypedArray( Class )){include TestBenchFactorArray}).new #awkward, but it works.
  end
end
