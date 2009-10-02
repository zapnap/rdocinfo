require "#{File.dirname(__FILE__)}/spec_helper"

describe 'RdocInfo::GemDocBuilder' do
  before(:each) do
    RdocInfo::Gem.all.destroy!

    @gem = Factory.build(:gem)
    @doc = RdocInfo::GemDocBuilder.new(@gem)
    @rdoc_dir = "#{RdocInfo.config[:rdoc_dir]}/default/spreadhead/versions/0.6.2"
    @tmp_dir  = "#{RdocInfo.config[:tmp_dir]}/spreadhead/versions/0.6.2"
  end

  it 'should have an rdoc url' do
    @doc.rdoc_url.should == "#{RdocInfo.config[:rdoc_url]}/spreadhead/versions/0.6.2"
  end

  it 'should have an rdoc dir' do
    @doc.rdoc_dir.should == "#{RdocInfo.config[:rdoc_dir]}/default/spreadhead/versions/0.6.2"
  end

  it 'should have a unpack dir' do
    @doc.unpack_dir.should == "#{RdocInfo.config[:tmp_dir]}/spreadhead-0.6.2"
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

    it 'should set status flag to created' do
      @doc.generate(false)
      @doc.gem.status.should == 'created'
    end

    it 'should set status flag to failed' do
      @doc.expects(:yardoc_command).returns('echo')
      @doc.generate(false)
      @doc.gem.status.should == 'failed'
    end

    it 'should save generation output' do
      @doc.expects(:yardoc_command).returns('echo out')
      @doc.generate(false)
      @doc.gem.error_log.chomp.should == 'out'
    end
  end

  private

  def dot_document_data
    File.read("#{File.expand_path(File.dirname(__FILE__))}/example.document")
  end
end
