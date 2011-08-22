# Provide methodology for adding contexts (filesystem, caching, etc.)
# in an abstract way. These will get mixed in at the iteration level.
module Context
  class Base
    include PhpIni::Inheritable

    def initialize host, middleware, php_build
      @host = host
      @middleware = middleware
      @php_build = php_build
    end
    attr_reader :host, :middleware, :php_build

    def up
      # do what needs to be done on setup
    end

    def down
      # do what needs to be done on teardown
    end
  end
end