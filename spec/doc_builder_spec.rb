require "#{File.dirname(__FILE__)}/spec_helper"

describe 'RdocInfo::DocBuilder' do
  before(:each) do
    RdocInfo::Project.all.destroy!

    Git.stubs(:open).returns(@github_pages = stub_everything('Git'))
    @project = Factory.build(:project)
    @doc = RdocInfo::DocBuilder.new(@project)

    @rdoc_dir = "#{RdocInfo.config[:rdoc_dir]}/default/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f"
    @tmp_dir  = "#{RdocInfo.config[:tmp_dir]}/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f"
  end

  it 'should have an rdoc url' do
    @doc.rdoc_url.should == "#{RdocInfo.config[:rdoc_url]}/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f"
  end

  it 'should have an rdoc dir' do
    @doc.rdoc_dir('default').should == "#{RdocInfo.config[:rdoc_dir]}/default/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f"
  end

  it 'should have an rdoc dir for github' do
    @doc.rdoc_dir('github').should == "#{RdocInfo.config[:rdoc_dir]}/github/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f"
  end

  it 'should have a clone dir' do
    @doc.clone_dir.should == "#{RdocInfo.config[:tmp_dir]}/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f"
  end

  describe 'RDoc generation' do
    before(:each) do
      FileUtils.rm_rf @rdoc_dir
      FileUtils.rm_rf @tmp_dir
    end

    it 'should place rdoc in public directory' do
      @doc.generate(false)
      File.exists?("#{@rdoc_dir}/index.html").should be_true
    end

    it 'should clean clone directory after build' do
      @doc.generate(false)
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
      @doc.send(:included_files).should == "'README.rdoc' 'lib/**/*.rb' 'History.txt' 'MIT-LICENSE.txt'"
    end

    # TODO: refactor target (private method)
    it 'should default to including all files in lib' do
      File.expects(:exists?).returns(false)
      @doc.send(:included_files).should == ''
    end

    it 'should exist on disk' do
      @doc.exists?.should be_false
      @doc.generate(false)
      @doc.exists?.should be_true
    end

    it 'should push updated pages to the remote' do
      @github_pages.receives(:add_remote)
      @github_pages.receives(:pull)
      @github_pages.receives(:add)
      @github_pages.receives(:commit)
      @github_pages.receives(:push)
      @doc.generate(false)
    end
    
  end

  describe 'RDoc template' do
    before(:each) do
      FileUtils.rm_rf @rdoc_dir
      FileUtils.rm_rf @tmp_dir      
      @doc.generate(false)
      @github_dir = @doc.rdoc_dir('github')
    end
    
    it 'should use absolute links for namespaces' do
      IO.read("#{@github_dir}/namespaces/index.html").should =~ /"\/zapnap\/simplepay\/blob\/0f115cd0b8608f677b676b861d3370ef2991eb5f\/Simplepay.html"/	
    end
    
    it 'should use absolute links for methods' do
      IO.read("#{@github_dir}/methods/index.html").should =~ /"\/zapnap\/simplepay\/blob\/0f115cd0b8608f677b676b861d3370ef2991eb5f\/Simplepay\/Authentication.html#authentic-3F-class_method"/	
    end
    
    it 'should use absolute links for the namespaces link popup' do
      IO.read("#{@github_dir}/namespaces/index.html").scan("var url=\"/\"+$(this).attr('rel')+\"/namespaces/\"").size == 1;                  
    end
    
    it 'should use absolute links for the methods link popup' do
      IO.read("#{@github_dir}/methods/index.html").scan("var url=\"/\"+$(this).attr('rel')+\"/methods/\"").size == 1;                  
    end

    it 'should generate a redirect page for the latest commit' do
      IO.read("#{@github_dir}/../../index.html").scan("url=http://docs.github.com/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f").size == 1;                  
    end

  end  

  private

  def dot_document_data
    File.read("#{File.dirname(__FILE__)}/example.document")
  end
end
