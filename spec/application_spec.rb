require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  before(:each) do
    Project.all.destroy!
    @project = Factory(:project)
  end

  describe 'index' do
    it 'should show a list of projects' do
      get '/'
      last_response.should be_ok
      last_response.body.should have_tag("li#project-#{@project.id}")
    end
  end

  describe 'project pages' do
    it 'should show the project rdoc' do
      get "/projects/#{@project.id}"
      last_response.should be_ok
    end
  end

  describe 'post-commit hook' do
    before(:each) do
    end

    it 'should retrieve the appropriate project' do
      pending
    end
  end
end
