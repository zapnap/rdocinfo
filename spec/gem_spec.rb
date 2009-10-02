require "#{File.dirname(__FILE__)}/spec_helper"

describe 'RdocInfo::Gem' do
  before(:each) do
    RdocInfo::Gem.all.destroy!
    @gem = Factory.build(:gem)
  end

  it 'should be valid' do
    @gem.should be_valid
  end

  it 'should have a public doc url' do
    @gem.doc_url.should == '/gems/spreadhead/versions/0.6.2'
  end

  it 'should have a gem url' do
    @gem.gem_url.should == 'http://s3.amazonaws.com/gemcutter_production/gems/spreadhead-0.6.2.gem'
  end

  it 'should have a version url' do
    @gem.version_url.should == 'http://gemcutter.org/gems/spreadhead/versions/0.6.2'
  end

  it 'should update the status and avoid regeneration' do
    @gem.doc.expects(:regenerate).never
    @gem.update_status!('created')
    @gem.status.should == 'created'
  end

  describe 'validations' do
    before(:each) do
      @gem.stubs(:doc).returns(@doc = stub_everything('RdocInfo::GemDocBuilder'))
    end

    it 'should require a name' do
      @gem.name = nil
      @gem.should_not be_valid
      @gem.errors[:name].should include("Name must not be blank")
    end

    it 'should require a url' do
      @gem.url = nil
      @gem.should_not be_valid
      @gem.errors[:url].should include("Url must not be blank")
    end

    it 'should require a unique version' do
      @gem.save
      @gem = Factory.build(:gem)
      @gem.should_not be_valid
      @gem.errors[:version].should include("Version is already taken")
    end
    
    it 'should require a valid gemcutter gem' do
      @gem.name = 'blahblahblahblahblah'
      @gem.url = "http://gemcutter.org/gems/#{@gem.name}"
      @gem.should_not be_valid
      @gem.errors[:name].should include("Name must refer to a valid gem hosted at gemcutter.org")
    end
    
    it 'should not allow non-ascii characters in the name' do
      @gem.name = 'haxor?you=ls+-al+/'
      @gem.should_not be_valid
      @gem.errors[:name].should include("Name contains disallowed characters")
    end

  end

  it 'should have a document builder' do
    RdocInfo::GemDocBuilder.expects(:new).with(@gem)
    @gem.doc
  end

  it 'should auto-generate docs after save' do
    @gem.stubs(:doc).returns(@doc = stub_everything('RdocInfo::GemDocBuilder'))
    @doc.expects(:generate)
    @gem.save
  end

  describe 'search' do
    before(:each) do
      @gem.stubs(:doc).returns(@doc = stub_everything('RdocInfo::GemDocBuilder'))
    end

    it 'should raise ArgumentError if :terms kwarg not supplied' do
      lambda { RdocInfo::Gem.search(:fields => :name) }.should raise_error(ArgumentError)
    end

    it 'should raise ArgumentError if :fields kwarg not supplied' do
      lambda { RdocInfo::Gem.search(:terms => 'foo') }.should raise_error(ArgumentError)
    end

    it 'should return all results if :page and :count kwarg not supplied' do
      RdocInfo::Gem.expects(:all)
      RdocInfo::Gem.search(:fields => :name, :terms => 'foo')
    end

    it 'should return paginated results if :page kwarg is supplied' do
      RdocInfo::Gem.expects(:paginated)
      RdocInfo::Gem.search(:page => 1, :fields => :name, :terms => 'foo')
    end

    it 'should return paginated results if :count kwarg is supplied' do
      RdocInfo::Gem.expects(:paginated)
      RdocInfo::Gem.search(:count => 10, :fields => :name, :terms => 'foo')
    end

    it 'should return paginated results if :page and :count kwargs are supplied' do
      RdocInfo::Gem.expects(:paginated)
      RdocInfo::Gem.search(:page => 1, :count => 10, :fields => :name, :terms => 'foo')
    end

    it 'should default to RdocInfo.config settings if :count kwarg not supplied' do
      RdocInfo::Gem.expects(:paginated).with(:order => [:name],
                                       :fields => [:name],
                                       :conditions => ['(name LIKE ?)', '%foo%'],
                                       :unique => true,
                                       :per_page => RdocInfo.config[:per_page],
                                       :page => 1)
      RdocInfo::Gem.search(:page => 1, :fields => :name, :terms => 'foo')
    end

    it 'should default to first page if :page kwarg not supplied' do
      RdocInfo::Gem.expects(:paginated).with(:order => [:name],
                                       :fields => [:name],
                                       :conditions => ['(name LIKE ?)', '%foo%'],
                                       :unique => true,
                                       :per_page => 10,
                                       :page => 1)
      RdocInfo::Gem.search(:count => 10, :fields => :name, :terms => 'foo')
    end

    [{:fields => :name, :terms => 'spread'},
     {:fields => [:name], :terms => ['spread']}].each do |args|
      fields = [args[:fields]].flatten.map {|f| f.to_s}.join(' or ')
      terms = [args[:terms]].join(' and ')

      it "should return spreadhead searching fields #{fields} for #{terms}" do
        @gem.save
        gems = RdocInfo::Gem.search(args)
        gems.first.name.should == 'spreadhead'
      end

      it "should return page count and spreadhead searching fields #{fields} for #{terms} with pagination" do
        @gem.save
        args[:page] = 1
        pages, gems = RdocInfo::Gem.search(args)
        pages.should == 1
        gems.first.name.should == 'spreadhead'
      end
    end

    [{:fields => [:name], :terms => 'headword'}].each do |args|
      fields = args[:fields].map {|f| f.to_s}.join(' or ')
      terms = [args[:terms]].join(' and ')

      it "should return no gems searching fields #{fields} for #{terms}" do
        @gem.save
        RdocInfo::Gem.search(args).should == []
      end

      it "should return zero page count and no gems searching fields #{fields} for #{terms} with pagination" do
        @gem.save
        args[:page] = 1
        RdocInfo::Gem.search(args).should == [0, []]
      end
    end
  end
end
