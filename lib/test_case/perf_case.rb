
module TestCase
  class PerfCase
    def initialize(url_path, app_name, index='/')
      @url_path = url_path
      @app_name = app_name
      @index = index
    end
  end
end