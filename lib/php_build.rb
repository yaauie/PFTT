class PhpBuild
  include TestBenchFactor

  def initialize path, hsh={}
    set_buildinfo( path )
    @php_path = path
  end

  def [](k)
    @buildinfo[k.to_sym]
  end

  protected

  def set_buildinfo path
    @buildinfo={}
    parts = File.basename(path).split('-')
    
    requirement :platform => !parts.select{|i| i =~/(Win32|windows)/ }.empty? ? :windows : :linux

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
  end

  def to_s
    File.basename(@php_path)
  end

  def base_ini
    PhpIni.new 'date.timezone=GMT',"extension_dir=\"#{File.join( @php_path, 'ext' )}\""
  end
end
