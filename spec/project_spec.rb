require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Project' do
  before(:each) do
    Project.all.destroy!
    @project = Factory.build(:project)
  end

  it 'should be valid' do
    @project.should be_valid
  end

  it 'should have a public doc url' do
    @project.doc_url.should == '/projects/zapnap/simplepay'
  end

  it 'should have a clone url' do
    @project.clone_url.should == 'git://github.com/zapnap/simplepay.git'
  end

  describe 'validations' do
    before(:each) do
      @project.stubs(:doc).returns(@doc = stub_everything('DocBuilder'))
    end

    it 'should require a name' do
      @project.name = nil
      @project.should_not be_valid
      @project.errors[:name].should include("Name must not be blank")
    end

    it 'should require an owner' do
      @project.owner = nil
      @project.should_not be_valid
      @project.errors[:owner].should include("Owner must not be blank")
    end

    it 'should require a url' do
      @project.url = nil
      @project.should_not be_valid
      @project.errors[:url].should include("Url must not be blank")
    end

    it 'should require a unique url' do
      @project.save
      @project = Factory.build(:project)
      @project.should_not be_valid
      @project.errors[:url].should include("Url is already taken")
    end
    
    it 'should require a valid github repository' do
      @project.name = 'blahblahblahblahblah'
      @project.should_not be_valid
      @project.errors[:name].should include("Name must refer to a valid GitHub repository")
    end
  end

  it 'should have a document builder' do
    DocBuilder.expects(:new).with(@project)
    @project.doc
  end

  it 'should auto-generate docs after save' do
    @project.stubs(:doc).returns(@doc = stub_everything('DocBuilder'))
    @doc.expects(:generate)
    @project.save
  end
end
