module Subdomainify

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
        name = subroute.defaults[:controller].split('/').last.to_s.singularize
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
