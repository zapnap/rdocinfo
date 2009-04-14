require "#{File.dirname(__FILE__)}/spec_helper"

describe 'DocBuilder' do
  before(:each) do
    Project.all.destroy!
    @project = Factory.build(:project)
    @doc = DocBuilder.new(@project)

    @rdoc_dir = File.expand_path(File.dirname(__FILE__) + '/rdoc')
    @tmp_dir = File.expand_path(File.dirname(__FILE__) + '/tmp')
  end

  it 'should have an rdoc dir' do
    @doc.rdoc_dir.should == "#{SiteConfig.rdoc_dir}/zapnap/simplepay"
  end

  it 'should have a clone dir' do
    @doc.clone_dir.should == "#{SiteConfig.tmp_dir}/zapnap/simplepay"
  end

  describe 'RDoc generation' do
    before(:each) do
      @doc.stubs(:rdoc_dir).returns(@rdoc_dir)
      @doc.stubs(:clone_dir).returns(@tmp_dir)

      FileUtils.rm_rf @rdoc_dir
      FileUtils.rm_rf @tmp_dir
    end

    it 'should place rdoc in public directory' do
      @doc.generate
      File.exists?("#{@rdoc_dir}/index.html").should be_true
    end

    it 'should clean clone directory after build' do
      @doc.generate
      File.exists?("#{@tmp_dir}}").should be_false
    end

    it 'should choose a README file' do
      Dir.expects(:[]).returns(['README.rdoc'])
      @doc.readme_file.should == 'README.rdoc'
    end

    it 'should create an empty README file if one cannot be found' do
      Dir.expects(:[]).returns([])
      File.stubs(:open).returns(nil) # don't actually write the file
      @doc.readme_file.should == 'README' # generated
    end

    it 'should exist on disk' do
      @doc.exists?.should be_false
      @doc.generate
      @doc.exists?.should be_true
    end
  end
end
