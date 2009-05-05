class SpecFileWatcher
  def fetch_spec_file
    fetcher = Gem::SpecFetcher.new
    fetcher.load_specs(URI.parse('http://gems.github.com/'), 'specs')
  end
  
  def dump_spec_info(specs)
    big_hash = {}
    specs.each {|spec| big_hash[spec[0]] = "#{spec[1]}" }
    YAML.dump(big_hash)    
  end
end