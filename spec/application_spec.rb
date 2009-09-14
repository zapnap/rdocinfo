require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Application' do
  include Rack::Test::Methods

  def app
    RdocInfo::Application.new
  end
  
  before(:each) do
    @per_page = RdocInfo.config[:per_page]

    RdocInfo::Project.all.destroy!
    RdocInfo::Project.any_instance.stubs(:doc).returns(@doc = stub_everything('RdocInfo::DocBuilder'))

    @project = Factory.build(:project)
    @project.save
  end

  describe 'index' do
    it 'should show a list of projects' do
      get '/projects'
      last_response.should be_ok
      last_response.body.should have_tag("li#project-#{@project.owner}-#{@project.name}")
    end

    it 'should retrieve the second page of results' do
      RdocInfo::Project.expects(:paginated).with(:order => [:created_at.desc],
                                       :fields => [:owner, :name],
                                       :status => 'created',
                                       :unique => true,                                          
                                       :per_page => @per_page,
                                       :page => 2).returns([3, [@project]])
      get '/page/2'
    end
  end

  describe 'search' do
    it 'should redirect to / on with no search term' do
      get '/projects/search'
      follow_redirect!
      last_request.url.should match(/\//)
    end

    ['simple', 'simple nap', 'simple^nap'].each do |term|
      it "should find zapnap-simplepay for search term: #{term}" do
        get "/projects/search?q=#{URI.escape(term)}"
        last_response.should be_ok
        last_response.body.should have_tag("li#project-#{@project.owner}-#{@project.name}")
      end
    end

    ['foo', 'foo nap', 'foo^nap'].each do |term|
      it "should not find zapnap-simplepay for search term: #{term}" do
        get "/projects/search?q=#{URI.escape(term)}"
        last_response.should be_ok
        last_response.body.should_not have_tag("li#project-#{@project.owner}-#{@project.name}")
      end
    end

    it 'should find projects with weird names' do
      @project = Factory.build(:project, :name => 'A_Weird-1')
      @project.save!
      get "/projects/search?q=#{URI.escape('A_Weird-1')}"
      last_response.should be_ok
      last_response.body.should have_tag("li#project-#{@project.owner}-#{@project.name}")
    end
    
    it 'should not find projects with really weird names' do
      @project = Factory.build(:project, :owner => 'Muppet', :name => 'Balls')
      @project.save!
      get "/projects/search?q=#{URI.escape('_weird-1-a')}"
      last_response.should be_ok
      last_response.body.should_not have_tag("li#project-#{@project.owner}-#{@project.name}")
    end
    
    it 'should retrieve the second page of results for search term: nap' do
      RdocInfo::Project.expects(:paginated).with(:order => [:owner, :name],
                                       :fields => [:owner, :name],
                                       :conditions => ['(owner LIKE ? OR name LIKE ?)', '%nap%', '%nap%'],
                                       :unique => true,
                                       :per_page => @per_page,
                                       :page => 2).returns([3, [@project]])
      get '/projects/search?q=nap&page=2'
    end

    it 'should set the url for pagination' do
      RdocInfo::Project.stubs(:search).returns([@per_page + 1, [@project]*(@per_page + 1)])
      get '/project/search?q=nap'
      last_response.body.should have_tag('a[@href*=/project/search?q=nap&page=2')
    end

    it 'should preset the search params after search' do
      get '/projects/search?q=nap'
      last_response.body.should have_tag('input[@value=nap]')
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
        post '/projects', :owner => 'zapnap', :name => 'isbn_validation', :commit_hash => '1f115cd0b8608f677b676b861d3370ef2991eb5f'
      }.should change(RdocInfo::Project, :count).by(1)
    end

    it 'should redirect to the rdoc if successful' do
      post '/projects', :owner => 'zapnap', :name => 'isbn_validation'
      follow_redirect!
      last_request.url.should match(/.*projects\/zapnap\/isbn_validation.*$/)
    end

    it 'should redirect to the return url if provided' do
      post '/projects', :owner => 'zapnap', :name => 'isbn_validation', :return => 'http://blog.zerosum.org/'
      follow_redirect!
      last_request.url.should == 'http://blog.zerosum.org/'
    end

    it 'should re-render the new template if save fails' do
      post '/projects', :owner => 'zapnap', :name => 'simplepay'
      last_response.should be_ok
      last_response.body.should have_tag('form[@action=/projects]')
    end

    it 'should redirect back to return url if latest commit hash already exists' do
      post '/projects', :owner => 'zapnap', :name => 'simplepay', :return => 'http://blog.zerosum.org/something'
      follow_redirect!
      last_request.url.should == 'http://blog.zerosum.org/something'
    end
  end

  describe 'post-commit hook' do
    it 'should update the specified project' do
      RdocInfo::Project.expects(:first).with(:owner => 'zapnap', :name => 'simplepay', :commit_hash => '0f115cd0b8608f677b676b861d3370ef2991eb5f').returns(@project)
      post '/projects/update', :payload => json_data
      last_response.status.should == 202
    end

    it 'should auto-create the project' do
      RdocInfo::Project.all.destroy!
      lambda {
        post '/projects/update', :payload => json_data
      }.should change(RdocInfo::Project, :count).by(1)
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
      RdocInfo::Project.stubs(:first).returns(@project)
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

    it 'should display errors if something bad happened during doc generation' do
      @project.doc.expects(:exists?).returns(false)
      @project.expects(:status).returns('failed')
      get '/projects/zapnap/simplepay'
      last_response.should be_ok
      last_response.body.should have_tag('p.error')
    end

    it 'should display rdocs for the specified commit hash' do
      RdocInfo::Project.expects(:first).with(:name => 'simplepay', :owner => 'zapnap', :commit_hash => '0f115cd0b8608f677b676b861d3370ef2991eb5f')
      get '/projects/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f/status'
    end

    it 'should grab the latest commit if hash is unspecified' do
      RdocInfo::Project.expects(:first).with(:name => 'simplepay', :owner => 'zapnap', :order => [:id.desc])
      get '/projects/zapnap/simplepay'
    end

    it 'should return 404 if the project does not exist' do
      RdocInfo::Project.stubs(:first).returns(nil)
      get '/projects/abcdefghijklmonop/qrstuvwxyz'
      last_response.status.should == 404
    end
  end

  describe 'build status' do
    before(:each) do
      RdocInfo::Project.stubs(:first).returns(@project)
    end

    it 'should return success if the project rdoc has been built'  do
      @project.expects(:status).returns('created')
      get '/projects/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f/status'
      last_response.status.should == 205
    end

    it 'should indicate that there was an error if the docs failed to generate'  do
      @project.expects(:status).returns('failed')
      lambda {
        get '/projects/zapnap/simplepay/blob/0f115cd0b8608f677b676b861d3370ef2991eb5f/status'
      }.should raise_error(RdocInfo::DocBuilderError)
    end

    it 'should return 404 if the project rdocs do not exist yet' do
      @project.expects(:status).returns(nil)
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
