class Article
  extend ActiveModel::Naming

  ARTICLES = [{ blog_slug: "foo", title: "Hello, world", slug: "hello-world" },
              { blog_slug: "foo", title: "Lorem",        slug: "lorem" },
              { blog_slug: "bar", title: "Example!",     slug: "example" }]

  attr_accessor :blog_slug, :title, :slug

  def self.find_by_blog_slug(slug)
    ARTICLES.select { |article| article[:blog_slug] == slug }.map do |article|
      Article.new(article)
    end
  end

  def self.find_by_slug(slug)
    Article.new(ARTICLES.find { |article| article[:slug] == slug })
  end

  def initialize(params)
    self.blog_slug = params[:blog_slug]
    self.title = params[:title]
    self.slug = params[:slug]
  end

  def to_param
    self.slug
  end
end
