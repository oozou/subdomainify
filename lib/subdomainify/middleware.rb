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
        if !request.path_info.start_with?('/assets/') && _route.present?
          env['PATH_INFO'] = [
            _route.format(id: request.subdomain),
            request.path_info,
          ].select { |p| p.present? && p != '/' }.join('/').gsub(%r{//}, '/')
        end
      end

      @app.call(env)
    end

  end

end
