module Subdomainify

  # Private: Middleware for rewriting PATH_INFO from subdomain.
  #
  # This is where URL rewriting magic takes place. It works by scanning
  # routes for anything with :subdomainify option and take the route with
  # highest precedence value (the "topmost" route) and use that as a
  # base path.
  #
  # For example, if we have these lines in routes:
  #
  #   resources :blogs, :subdomainify => true do
  #     resources :articles
  #     resources :comments
  #   end
  #
  # When user visited this URL:
  #
  #   http://foo.example.com/articles/hello-world
  #
  # This middleware will rewrite `PATH_INFO` into:
  #
  #   /blogs/foo/articles/hello-world/
  #
  class Middleware

    # Private: Initialize Rack Middleware.
    def initialize(app)
      @app = app
    end

    # Private: Rewrite PATH_INFO if appropriate and calls Rack application.
    def call(env)
      request = ActionDispatch::Request.new(env)
      routes = env['action_dispatch.routes']

      if request.subdomain.present? && request.subdomain != 'www'
        _route = routes.routes.select { |r| r.defaults[:subdomainify] }.last
        if !request.path_info.starts_with?('/assets/') && _route.present?
          env['PATH_INFO'] = [
            _route.format(id: request.subdomain),
            request.path_info,
          ].select { |p| p.present? && p != '/' }.join('/').gsub(%r{//}, '/')
        end
      end

      @app.call(env)
    end

  end

  # Private: Provide an implement for Rails' hook point.
  class Railtie < Rails::Railtie
    railtie_name :subdomainify

    initializer 'subdomainify.middleware' do |app|
      app.middleware.use 'Subdomainify::Middleware'
    end

    initializer 'subdomainify.url_for' do |app|
      routeset = ActionDispatch::Routing::RouteSet
      routeset.send :include, Subdomainify::RouteSet
      routeset.send :alias_method_chain, :url_for, :subdomain

      # In Rails 4, Rails won't be using RouteSet#url_for in situation where
      # nothing else but :controller and :action is present in route. This
      # "optimized route" behavior breaks our url_for overrides.
      #
      # See also: https://github.com/rails/rails/issues/12420
      # Also related: https://github.com/svenfuchs/routing-filter/issues/47
      routeset::NamedRouteCollection::UrlHelper.class_eval do
        def self.optimize_helper?(route)
          false
        end
      end
    end
  end

  # Private: Module for rewriting plain path into subdomain path.
  module RouteSet

    # Public: Rewrite normal route into route with subdomain if user links
    # to or from subdomain enabled routes. In such situation, :only_path
    # option will be ignored.
    def url_for_with_subdomain(options)
      options = default_url_options.merge(options || {})

      if needs_subdomain?(options)
        options[:only_path] = false

        # Use route with highest precedence value (i.e. shortest route).
        # TODO: Better ways to detect part name for nested resource?
        subroute = @set.select { |route| route.defaults[:subdomainify] }.last
        name = subroute.defaults[:controller].split("/").last.to_s.singularize
        name = subroute.name if subroute.name.present?
        subdomain_id = options[:"#{name}_id"] || options[:id]

        # On realm transfer, when user links from subdomain route to
        # bare route (i.e. :subdomainify is false) then we don't really
        # need subdomain to be present even if subdomain id is present.
        if options[:subdomainify] && subdomain_id
          options[:subdomain] = subdomain_id.to_param
        else
          default_options = ActionController::Base.default_url_options
          options[:subdomain] = default_options[:subdomain]
        end

        # Turn /blog/foo/articles/ to just /articles/ using subroute prefix.
        prefix = subroute.format(id: options[:subdomain])
        url = URI.parse(url_for_without_subdomain(options))
        url.path.gsub!(/^#{prefix}\/?/, '/')
        url.to_s
      else
        url_for_without_subdomain(options)
      end
    end

    protected

    # Private: Returns true if subdomain should be generated, such as when
    # linking to subdomain path or when transferring realm (e.g. linking
    # from subdomain path to non-subdomain path or vice versa.)
    def needs_subdomain?(options)
      options[:subdomainify].present? ||                  # Presence.
      get_realm(options) != get_realm(options[:_recall])  # Realm transfer.
    end

    # Private: Returns the realm of provided path options matched by
    # controller and action name. Realm could be either :subdomain or :bare.
    def get_realm(options)
      return :bare if options.blank?

      route = @set.select do |route|
        route.defaults[:controller] == options[:controller] &&
        route.defaults[:action] == options[:action]
      end.last

      if (route.try(:defaults) || {})[:subdomainify].present?
        :subdomain
      else
        :bare
      end
    end

  end

end
