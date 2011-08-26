class PhpBuild
  include TestBenchFactor
  include PhpIni::Inheritable

  def self.get_set(*globs)
    set = Class.new(TypedArray( self )){include TestBenchFactorArray}.new
    globs.each do |glob|
      Dir.glob( glob ) do |php|
        next if php.end_with? '.zip'
        set << PhpBuild.new( php )
      end
    end
    set
  end

  def initialize path, hsh={}
    @path = path
    puts path
    determine_properties_and_requirements
  end
  attr_reader :path

  def [](k)
    properties.merge(requirements)[k]
  end

  protected

  def determine_properties_and_requirements
    parts = File.basename(path).split('-')
    
    requirement :platform => !parts.select{|i| i =~/(Win32|windows)/ }.empty? ? :windows : :posix

    branchinfo = parts.select{|i| i =~ /[0-9]\.[0-9]+/ }.first

    property :php_branch => branchinfo.split('.').first(2).join('.')
    property :threadsafe => parts.select{|i| i == 'nts' }.empty?
    property :revision => (parts.select{|i| i =~ /r[0-9]+/ }).first

    
    property :type => case
      when branchinfo =~ /RC/          then :release_candidate
      when property(:revision).nil?    then :snap
      when branchinfo =~ /alpha|beta/  then :prerelease
      else :release
    end
    property :compiler => (parts.select{|i| i =~ /vc[0-9]+/i }).first.upcase

    property :version => [
      branchinfo,
      property(:revision)
    ].compact.join('-')
    self
  end

  def to_s
    File.basename(path)
  end

  ini <<-INI
    ;date.timezone is not in the defaults from run-tests.php,
    ;but 5.3 test cases require this to be set, and doing so 
    ;seems to eliminate some failures
    date.timezone=UTC
  INI
end
