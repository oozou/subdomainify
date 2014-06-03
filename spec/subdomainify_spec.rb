require 'spec_helper'

describe Subdomainify do
  let(:set) { ActionDispatch::Routing::RouteSet.new }

  before do
    set.draw do
      resources :baz
      resources :hoge
      resources :foo, subdomainify: true do
        resources :bar
      end
    end
  end

  describe Subdomainify::Middleware do

    class MockRackApp
      def call(env)
        env
      end
    end

    let(:app) { Subdomainify::Middleware.new(MockRackApp.new) }

    def make_response(path, host, opts={})
      app.call(opts.merge('action_dispatch.routes' => set,
                          'PATH_INFO' => path,
                          'HTTP_HOST' => host))
    end

    it "should rewrite subdomain route" do
      response = make_response('/', 'bar.example.com')
      expect(response['PATH_INFO']).to eq '/foo/bar'
      expect(response['HTTP_HOST']).to eq 'bar.example.com'
    end

    it "should rewrite subdomain route with path" do
      response = make_response('/bar/1', 'bar.example.com')
      expect(response['PATH_INFO']).to eq '/foo/bar/bar/1'
      expect(response['HTTP_HOST']).to eq 'bar.example.com'
    end

    it "should bypass route without subdomain" do
      response = make_response('/foo', 'example.com')
      expect(response['PATH_INFO']).to eq '/foo'
      expect(response['HTTP_HOST']).to eq 'example.com'
    end

    it "should bypass route with www subdomain" do
      response = make_response('/foo', 'www.example.com')
      expect(response['PATH_INFO']).to eq '/foo'
      expect(response['HTTP_HOST']).to eq 'www.example.com'
    end

    it "should bypass route if subdomain route is not present" do
      set.clear!
      response = make_response('/', 'bar.example.com')
      expect(response['PATH_INFO']).to eq '/'
      expect(response['HTTP_HOST']).to eq 'bar.example.com'
    end

    it "should bypass assets route" do
      response = make_response('/assets/foo/bar', 'bar.example.com')
      expect(response['PATH_INFO']).to eq '/assets/foo/bar'
      expect(response['HTTP_HOST']).to eq 'bar.example.com'
    end
  end

  describe Subdomainify::Railtie do
    it "should inject subdomain route utilities to action dispatch" do
      expect(set).to respond_to :url_for_with_subdomain
      expect(set).to respond_to :url_for_without_subdomain
    end

    it "should disable optimized url helper" do
      collection = ActionDispatch::Routing::RouteSet::NamedRouteCollection
      set.routes.each do |route|
        expect(collection::UrlHelper.optimize_helper?(route)).to be_falsey
      end
    end
  end

  describe Subdomainify::RouteSet do

    class RouteSetMock
      include Subdomainify::RouteSet

      def default_url_options
        {}
      end

      def initialize(set)
        @route = set
        @set = set.routes
      end

      def url_for_without_subdomain(options)
        options = { only_path: true }.merge(options)
        @route.url_for_without_subdomain(options)
      end
    end

    subject { RouteSetMock.new(set) }

    describe "#url_for_with_subdomain" do
      it "should construct subdomain url for linking to subdomain route" do
        expect(subject.url_for_with_subdomain({
          controller: "foo",
          action: "show",
          id: "foobar",
          subdomainify: true,
          host: "example.com",
          _recall: { controller: "baz", action: "show" },
        })).to eq "http://foobar.example.com/"
      end

      it "should construct subdomain url for nested resource" do
        expect(subject.url_for_with_subdomain({
          controller: "bar",
          action: "show",
          foo_id: "foobar",
          id: "1",
          subdomainify: true,
          host: "example.com",
          _recall: { controller: "baz", action: "show" },
        })).to eq "http://foobar.example.com/bar/1"
      end

      it "should construct subdomain url for linking from subdomain route" do
        expect(subject.url_for_with_subdomain({
          controller: "baz",
          action: "show",
          id: "1",
          host: "example.com",
          _recall: { controller: "foo", action: "show", id: "foobar" },
        })).to eq "http://example.com/baz/1"
      end

      it "should construct normal url when linking from and to normal route" do
        expect(subject.url_for_with_subdomain({
          controller: "hoge",
          action: "show",
          id: "1",
          host: "example.com",
          _recall: { controller: "baz", action: "show", id: "1" },
        })).to eq "/hoge/1"
      end

      it "should delegate default subdomain from action controller" do
        klass = Class.new(ActionController::Base)
        klass.default_url_options = { subdomain: 'www' }
        stub_const("ActionController::Base", klass)

        expect(subject.url_for_with_subdomain({
          controller: "baz",
          action: "show",
          id: "1",
          host: "example.com",
          _recall: { controller: "foo", action: "show", id: "foobar" },
        })).to eq "http://www.example.com/baz/1"
      end
    end

    describe "#needs_subdomain?" do
      it "should be true for subdomain route" do
        expect(subject.send(:needs_subdomain?, {
          controller: "bar",
          action: "show",
          subdomainify: true,
          _recall: { controller: "foo", action: "show" },
        })).to be_truthy
      end

      it "should be true for linking from subdomain realm to bare realm" do
        expect(subject.send(:needs_subdomain?, {
          controller: "baz",
          action: "show",
          _recall: { controller: "foo", action: "show" },
        })).to be_truthy
      end

      it "should be true for linking to subdomain realm from bare realm" do
        expect(subject.send(:needs_subdomain?, {
          controller: "foo",
          action: "show",
          _recall: { controller: "baz", action: "show" },
        })).to be_truthy
      end

      it "should be false for linking within same bare realm" do
        expect(subject.send(:needs_subdomain?, {
          controller: "baz",
          action: "show",
          _recall: { controller: "hoge", action: "show" },
        })).to be_falsey
      end
    end

    describe "#get_realm" do
      it "should return bare for normal route" do
        realm = subject.send(:get_realm, { controller: "baz", action: "show" })
        expect(realm).to eq :bare
      end

      it "should return bare if route options is not given" do
        realm = subject.send(:get_realm, {})
        expect(realm).to eq :bare
      end

      it "should return subdomain for subdomain route" do
        realm = subject.send(:get_realm, { controller: "foo", action: "show" })
        expect(realm).to eq :subdomain
      end

      it "should return subdomain for subdomain subroute" do
        realm = subject.send(:get_realm, { controller: "bar", action: "show" })
        expect(realm).to eq :subdomain
      end
    end

  end

end
