class Blog
  extend ActiveModel::Naming

  BLOGS = [{ name: "My Foo Blog",     slug: "foo", },
           { name: "My Awesome Blog", slug: "bar", }]

  attr_accessor :name, :slug

  def self.all
    BLOGS.map do |blog|
      Blog.new(blog)
    end
  end

  def self.find_by_slug(slug)
    Blog.new(BLOGS.find { |blog| blog[:slug] == slug })
  end

  def initialize(params)
    self.name = params[:name]
    self.slug = params[:slug]
  end

  def to_param
    self.slug
  end

  def articles
    Article.find_by_blog_slug(self.slug)
  end
end
