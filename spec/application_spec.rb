require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end
  
  before(:each) do
    Project.all.destroy!
    @project = Factory.build(:project)
    @project.stub!(:update_rdoc).and_return(true)
    @project.save
  end

  describe 'index' do
    it 'should show a list of projects' do
      get '/'
      last_response.should be_ok
      last_response.body.should have_tag("li#project-#{@project.id}")
    end
  end

  describe 'post-commit hook' do
    it 'should retrieve the appropriate project' do
      Project.should_receive(:first).with(:url => 'http://github.com/zapnap/simplepay').and_return(@project)
      @project.should_receive(:update_rdoc).and_return(true)
      post '/projects', :payload => json_data
      last_response.should be_ok
    end
  end

  private

  def json_data
    File.read("#{File.dirname(__FILE__)}/example.json")
  end
end
