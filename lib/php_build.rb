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

    @buildinfo[:platform] = !parts.select{|i| i =~/(Win32|windows)/ }.empty? ? :windows : :linux
    
    branchinfo = parts.select{|i| i =~ /[0-9]\.[0-9]+/ }.first
    @buildinfo[:branch] = branchinfo.split('.').first(2).join('.')
    @buildinfo[:threadsafe] = parts.select{|i| i == 'nts' }.empty?
    @buildinfo[:revision] = (parts.select{|i| i =~ /r[0-9]+/ }).first
    @buildinfo[:type] = case
      when branchinfo =~ /RC/          then :release_candidate
      when !@buildinfo[:revision].nil? then :snap
      when branchinfo =~ /alpha|beta/  then :prerelease
      else :release
    end
    @buildinfo[:compiler] = (parts.select{|i| i =~ /vc[0-9]+/i }).first.upcase

    @buildinfo[:version] = [
      branchinfo,
      @buildinfo[:revision]
    ].compact.join('-')
  end

  def to_s
    File.basename(@php_path)
  end

  def base_ini
    PhpIni.new 'date.timezone=GMT',"extension_dir=\"#{File.join( @php_path, 'ext' )}\""
  end
end
