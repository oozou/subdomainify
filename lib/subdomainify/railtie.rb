require 'rails'

module Subdomainify

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

end
