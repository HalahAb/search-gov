require "#{File.dirname(__FILE__)}/../../spec_helper"
describe "shared/_searchresults.html.haml" do
  before do
    @search = stub("Search")
    @search.stub!(:related_search).and_return []
    @search.stub!(:queried_at_seconds).and_return(1271978870)
    @search.stub!(:query).and_return "tax forms"
    @search.stub!(:spelling_suggestion)
    @search.stub!(:images).and_return []
    @search.stub!(:error_message)
    @search.stub!(:startrecord).and_return 1
    @search.stub!(:endrecord).and_return 10
    @search.stub!(:total).and_return 20
    @search.stub!(:page).and_return 0
    @search.stub!(:spotlight)
    @search.stub!(:boosted_contents)
    @search.stub!(:faqs)
    @search.stub!(:gov_forms)
    @search.stub!(:scope_id)
    @search.stub!(:fedstates)
    @search.stub!(:recalls)
    @deepLink.stub!(:title).and_return 'A title'
    @deepLink.stub!(:url).and_return 'http://adeeplink.com'
    @search_result = {'title' => "some title",
                     'unescapedUrl'=> "http://www.foo.com/url",
                     'content'=> "This is a sample result",
                     'cacheUrl'=> "http://www.cached.com/url",
                     'deepLinks' => [ @deepLink ]
    }
    @search_results = []
    @search_results.stub!(:total_pages).and_return 1
    @search.stub!(:results).and_return @search_results

    20.times { @search_results << @search_result }
    assigns[:search] = @search
  end

  context "when page is displayed" do

    it "should show a results summary" do
      render :locals => { :search => @search }
      response.should contain("Results 1-10 of about 20 for 'tax forms'")
    end

    it "should show deep links on the first page only" do
      render :locals => { :search => @search }
      response.should have_tag('table', :class => 'deep_links', :count => 1 )
    end

    context "when on anything but the first page" do
      before do
        @search.stub!(:page).and_return 1
      end

      it "should not show any deep links" do
        render :locals => { :search => @search }
        response.should_not have_tag('table', :class => 'deep_links')
      end
    end

    context "when a boosted Content is returned as a hit, but that boosted Content is not in the database" do
      before do
        boosted_content = BoostedContent.create(:title => 'test', :url => 'http://test.gov', :description => 'test')
        BoostedContent.reindex
        boosted_content.delete
        boosted_contents_results = BoostedContent.search_for("test")
        boosted_contents_results.hits.first.instance.should be_nil
        @search.stub!(:boosted_contents).and_return boosted_contents_results
      end

      it "should render the page without an error, and without boosted Contents" do
        render :locals => { :search => @search }
        response.should be_success
        response.body.should have_tag('div#boosted', :text => "")
      end
    end

    context "when a recall is found" do
      before do
        recall = Recall.create!(:recall_number => '23456', :recalled_on => Date.yesterday, :organization => 'CPSC')
        recall.recall_details << RecallDetail.new(:detail_type => 'Description', :detail_value => 'Recall details')
        recall_without_recalled_on = Recall.create!(:recall_number => '23456', :organization => 'CDC')
        recall_without_recalled_on.create_food_recall(:url => "http://www.fda.gov/", :summary => "bad drugs", :description => "bad drugs details", :food_type => "drug")
        Recall.reindex

        @search.stub!(:recalls).and_return(Recall.search_for("details"))
      end

      it "should render a govbox with recall links" do

        render :locals => { :search => @search }

        response.should be_success
        response.body.should have_tag('.recalls-govbox .details a', /details/)

      end
    end
  end
end
