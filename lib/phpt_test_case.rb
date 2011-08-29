class PhptTestCase

  include TestBenchFactor

  @@supported_sections = {
    :required => [
      [:file,:fileeof,:file_external],
      [:expect,:expectf,:expectregex],
      [:test]
    ],
    :optional => [
      #[:post,:post_raw],
      [:credit,:credits],
      [:ini],
      [:skipif],
      [:clean]
    ]
  }

  attr_reader :phpt_path

  def initialize( path )
    if !File.exists?( path ) 
      raise 'File not found: ['+path+']'
    end
    @phpt_path = path
  end

  def name
    File.basename @phpt_path, '.phpt'
  end

  def description
    @phpt_path
  end

  def expectation
    @expectation_type ||= (parts.keys & [:expect,:expectf,:expectregex]).first
    @expectation ||= {:type => @expectation_type, :content => self[@expectation_type]}
  end

  def options
    require 'yaml'
    if @options.nil?
      @options = YAML::load parts[:pftt] if parts[:pftt]
      @options ||= {}
    end
    @options
  end

  def ini
    @ini ||= PhpIni.new parts[:ini]
  end

  def bork_reasons
    borked?
    @bork_reasons
  end

  def borked?
    unless @bork_reasons
      @bork_reasons = []
      (@@supported_sections.values.flatten(1)).each do |group|
        if (parts.keys & group).length > 1
          @bork_reasons << 'duplicate sections:'+group.to_s
        end
      end
      @@supported_sections[:required].each do |group|
        if (parts.keys & group).length < 1;
          @bork_reasons << 'missing required section:'+group.to_s
        end
      end
    end
    !@bork_reasons.length.zero?
  end

  def unsupported?
    # are any sections in parts not present in @supported_sections
    !unsupported_sections.length.zero?
  end

  def unsupported_sections
    @unsupported_sections ||= (parts.keys - @@supported_sections.values.flatten)
  end

  def []( section )
    return parts[section] || nil
  end

  def save_section( section, path, extension=section.to_s )
    fullpath = File.join( path, "#{name}.#{extension}")
    File.open fullpath, 'w' do |file|
      file.write self[section]
    end
    fullpath
  end

  def extension
    {
      :file => 'php',
      :skipif => 'skipif.php',
      :clean => 'clean.php'
    }
  end

  def files
    # TODO: supporting files:
    # scenario 1: options[:support_files]

    # scenario 2: folder with same name as this test case

    # scenario 3: all folders alongside this and all files that are not phpt files
  end

  def attach_result( result )
    @result_tester.test( result ) unless @result_tester.raw == result
  end

  def pass?
    raise 'Result not attached' if @result_tester.nil?
    @result_tester.pass?
  end

  def inspect
    parts.inspect
  end

  protected

  def parse!
    @raw ||= IO.read(@phpt_path)
    reset!
    @result_tester = nil
    section = :none
    @raw.lines do |line|
      if line =~ /^--(?<section>[A-Z_]+)--/
        section = Regexp.last_match[:section].downcase.to_sym
        @parts[section]=''
      else
        @parts[section] += parse_line line, File.dirname( @phpt_path )
      end
    end

    if @parts.has_key? :fileeof
      @parts[:file]=@parts.delete(:fileeof).gsub(/\r?\n\Z/,'')
    elsif @parts.has_key? :file_external
      context = File.dirname( @phpt_path )
      external_file = File.absolute_path( @parts.delete(:file_external).gsub(/\r?\n\Z/,''), context ) 
      @parts[:file]= IO.read( external_file ).lines do |line|
        parse_line line, context
      end
    end
  end

  def reset!
    @parts = {}
    @ini = nil
    @options = nil
  end

  private

  def parse_line( line, context )
    return line unless line =~ /^\#\!?include (?<script>.*)/
    script = File.expand_path Regexp.last_match[:script].chomp, context
    expanded = ''
    IO.read(script).lines do |line|
      expanded += parse_line line, File.dir_name(script)
    end
    expanded
  end

  def parts
    parse! unless @parts
    @parts
  end
end

def PhptTestCase::Error
  def initialize(message=nil)
    @message = message
  end

  def to_s
    @message
  end
end

class PhptTestCase::Array < TypedArray(PhptTestCase)
  def load( *globs )
    globs.each do |glob|
      Dir.glob( glob ).each do |file|
        self << PhptTestCase.new( file )
      end
    end
    self
  end
end