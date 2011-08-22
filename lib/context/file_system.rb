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
  end
end