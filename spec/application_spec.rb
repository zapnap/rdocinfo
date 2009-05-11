require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  before(:each) do
    Project.all.destroy!
    Project.any_instance.stubs(:doc).returns(@doc = stub_everything('DocBuilder'))
    @project = Factory.build(:project)
    @project.save
  end

  describe 'index' do
    it 'should show a list of projects' do
      get '/projects'
      last_response.should be_ok
      last_response.body.should have_tag("li#project-#{@project.id}")
    end

    it 'should retrieve the second page of results' do
      Project.expects(:paginated).with(:order => [:created_at.desc],
                                       :per_page => SiteConfig.per_page,
                                       :page => 2).returns([3, [@project]])
      get '/page/2'
    end
  end

  describe 'new' do
    it 'should have a form for project submission' do
      get '/projects/new'
      last_response.should be_ok
      last_response.body.should have_tag('form[@action=/projects]')
    end
  end

  describe 'create' do
    it 'should create a new project' do
      lambda {
        post '/projects', :owner => 'zapnap', :name => 'isbn_validation'
      }.should change(Project, :count).by(1)
    end

    it 'should redirect to the rdoc' do
      post '/projects', :owner => 'zapnap', :name => 'isbn_validation'
      follow_redirect!
      last_request.url.should match(/.*projects\/zapnap\/isbn_validation.*$/)
    end
  end

  describe 'post-commit hook' do
    it 'should update the specified project' do
      Project.expects(:first).with(:url => 'http://github.com/zapnap/simplepay').returns(@project)
      @project.expects(:update_attributes).with(:commit_hash => '0f115cd0b8608f677b676b861d3370ef2991eb5f').returns(true)
      post '/projects/update', :payload => json_data
      last_response.status.should == 202
    end

    it 'should auto-create the project' do
      Project.all.destroy!
      lambda {
        post '/projects/update', :payload => json_data
      }.should change(Project, :count).by(1)
      last_response.status.should == 202
    end

    it 'should return 403 if unable to create the project' do
      post '/projects/update', :payload => '{}'
      last_response.status.should == 403
    end
  end

  describe 'show' do
    before(:each) do
      @project.save
    end

    it 'should display rdocs for the specified project' do
      @project.doc.expects(:exists?).returns(true)
      get '/projects/zapnap/simplepay'
      last_response.should be_ok
      last_response.body.should have_tag('div.title a', :text => @project.name)
    end

    it 'should display a work in progress page if the rdocs have not been built yet' do
      @project.doc.expects(:exists?).returns(false)
      get '/projects/zapnap/simplepay'
      last_response.should be_ok
      last_response.body.should have_tag('div.progress')
    end

    it 'should return 404 if the project does not exist' do
      get '/projects/abcdefghijklmonop/qrstuvwxyz'
      last_response.status.should == 404
    end
  end

  describe 'build status' do
    before(:each) do
      @project.save
    end

    it 'should return success if the project rdoc has been built'  do
      @project.doc.expects(:exists?).returns(true)
      get '/projects/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f/status'
      last_response.status.should == 205
    end

    it 'should return 404 if the project rdocs do not exist' do
      @project.doc.expects(:exists?).returns(false)
      get '/projects/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f/status'
      last_response.status.should == 404
    end
  end

  describe 'update' do
    before(:each) do
      @project.save
    end

    it 'should regenerate current documentation for the project' do
      @project.doc.expects(:generate)
      put '/projects/zapnap/simplepay'
      follow_redirect!
      last_request.url.should match(/.*projects\/zapnap\/simplepay.*$/)
    end

    it 'should return 404 if the project is not found' do
      get '/projects/abcdefghijklmnopqrstuvwxyz'
      last_response.status.should == 404
    end
  end

  private

  def json_data
    File.read("#{File.dirname(__FILE__)}/example.json")
  end
end
