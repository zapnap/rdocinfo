require "#{File.dirname(__FILE__)}/spec_helper"

describe 'DocBuilder' do
  before(:each) do
    Project.all.destroy!

    Git.stubs(:open).returns(@github_pages = stub_everything('Git'))
    @project = Factory.build(:project)
    @doc = DocBuilder.new(@project)

    @rdoc_dir = "#{SiteConfig.rdoc_dir}/zapnap/simplepay"
    @tmp_dir  = "#{SiteConfig.tmp_dir}/zapnap/simplepay"
  end

  it 'should have an rdoc url' do
    @doc.rdoc_url.should == "#{SiteConfig.rdoc_url}/zapnap/simplepay"
  end

  it 'should have an rdoc dir' do
    @doc.rdoc_dir.should == "#{SiteConfig.rdoc_dir}/zapnap/simplepay"
  end

  it 'should have a clone dir' do
    @doc.clone_dir.should == "#{SiteConfig.tmp_dir}/zapnap/simplepay"
  end

  describe 'RDoc generation' do
    before(:each) do
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

    # TODO: refactor target (private method)
    it 'should choose a README file' do
      Dir.expects(:[]).returns(['README.rdoc'])
      @doc.send(:readme_file).should == 'README.rdoc'
    end

    # TODO: refactor target (private method)
    it 'should create an empty README file if one cannot be found' do
      Dir.expects(:[]).returns([])
      File.stubs(:open).returns(nil) # don't actually write the file
      @doc.send(:readme_file).should == 'README' # generated
    end

    # TODO: refactor target (private method)
    it 'should use a .document file to specify included files' do
      data = dot_document_data
      File.expects(:exists?).returns(true)
      File.stubs(:read).returns(data)
      @doc.send(:included_files).should == '-q README.rdoc lib/**/*.rb History.txt MIT-LICENSE.txt'
    end

    # TODO: refactor target (private method)
    it 'should default to including all files in lib' do
      File.expects(:exists?).returns(false)
      @doc.send(:included_files).should == ''
    end

    it 'should exist on disk' do
      @doc.exists?.should be_false
      @doc.generate
      @doc.exists?.should be_true
    end

    it 'should push updated pages to the remote' do
      @github_pages.receives(:add_remote)
      @github_pages.receives(:pull)
      @github_pages.receives(:add)
      @github_pages.receives(:commit)
      @github_pages.receives(:push)
      @doc.generate
    end
    
  end

  describe 'RDoc template' do
    before(:each) do
      FileUtils.rm_rf @rdoc_dir
      FileUtils.rm_rf @tmp_dir
      @doc.generate
    end
    
    it 'should use absolute links for namespaces' do
      IO.read("#{@rdoc_dir}/namespaces/index.html").should =~ /"\/zapnap\/simplepay\/Simplepay.html"/	
    end
    
    it 'should use absolute links for methods' do
      IO.read("#{@rdoc_dir}/methods/index.html").should =~ /"\/zapnap\/simplepay\/Simplepay\/Authentication.html#authentic-3F-class_method"/	
    end
    
    it 'should use absolute links for the namespaces link popup' do
      IO.read("#{@rdoc_dir}/methods/index.html").scan("var url=\"/zapnap/simplepay\"+$(this).attr('rel')+\"/namespaces/\"").size == 1;                  
    end
    
    it 'should use absolute links for the methods link popup' do
      IO.read("#{@rdoc_dir}/methods/index.html").scan("var url=\"/zapnap/simplepay\"+$(this).attr('rel')+\"/methods/\"").size == 1;                  
    end

  end  

  private

  def dot_document_data
    File.read("#{File.dirname(__FILE__)}/example.document")
  end
end
