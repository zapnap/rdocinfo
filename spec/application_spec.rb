require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  before(:each) do
    Project.all.destroy!
    @project = Factory.build(:project)
    @project.stubs(:update_rdoc).returns(true)
    @project.save
  end

  describe 'index' do
    it 'should show a list of projects' do
      get '/'
      last_response.should be_ok
      last_response.body.should have_tag("li#project-#{@project.id}")
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
    before(:each) do
      Project.any_instance.stubs(:update_rdoc).returns(true)
    end

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
      @project.expects(:update_attributes).with(:commit_hash => 'de8251ff97ee194a289832576287d6f8ad74e3d0').returns(true)
      post '/projects/update', :payload => json_data
      last_response.status.should == 202
    end

    it 'should return 404 if the project does not exist' do
      Project.expects(:first).returns(nil)
      post '/projects/update', :payload => json_data
      last_response.status.should == 404
    end

    it 'should auto-create a project' do
      pending
    end
  end

  private

  def json_data
    File.read("#{File.dirname(__FILE__)}/example.json")
  end
end
