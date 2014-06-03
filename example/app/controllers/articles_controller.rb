class ArticlesController < ApplicationController

  def show
    @article = Article.find_by_slug(params[:id])
    @blog = Blog.find_by_slug(params[:blog_id])
  end

end
