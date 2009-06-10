require "#{File.dirname(__FILE__)}/spec_helper"
require "mocha"

describe 'RdocInfo::SpecFileWatcher' do
  before(:each) do
    @project = 'zzot-i_like_ruby_things_involving_muppets'
    @version = '0.0.1'
    @sample = [[@project, Gem::Version.new(@version), "ruby"]]
    @spec_file_watcher = RdocInfo::SpecFileWatcher.new
  end

  context 'no existing spec file' do
    it 'should grab the spec file from github' do  
      Gem::SpecFetcher.any_instance.expects(:load_specs).returns(@sample)
      specs = @spec_file_watcher.fetch_spec_file
      specs.should == @sample
    end
    
    it 'should save the latest specs to a yaml file' do
      YAML.expects(:dump).with({@project => @version})
      @spec_file_watcher.dump_spec_info(@sample)
    end
    
    
    it 'should generate rdoc for new projects in the spec file'
  end
  
  context 'we have a spec file and it has changed' do
    it 'should generate rdoc for new projects in the spec file'
    it 'should update rdoc for projects that have been updated in the spec file'
  end
end
