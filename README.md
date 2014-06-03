# Subdomainify [![Build Status](http://img.shields.io/travis/oozou/subdomainify.svg)](http://travis-ci.org/oozou/subdomainify)

Subdomainify is a subdomain rewriting middleware for your Rails 4 app.

## Installation

    gem "subdomainify"

TODO: more

## Usage

Simply mark any route in your `routes.rb` with `subdomainify: true`. For example:

```ruby
resources :blogs, subdomainify: true do
  resources :articles
  resources :comments
end
```

After marking a resource with `subdomainify`, a `url_for` call to that resource will automatically generate a subdomain route instead of a normal route. For example:

```ruby
@blog            # => #<Blog id: 1, user_id: 1, name: "My Example Blog", slug: "foo">
@blog.to_param   # => "foo"
blog_url(@blog)  # => "http://foo.example.com/"
```

This also works for nested resources:

```ruby
@article                           # => #<Article id: 1, user_id: 1, title: "Lorem ipsum", slug: "lorem-ipsum", body: "Dolor sit amet">
@article.to_param                  # => "lorem-ipsum"
blog_article_url(@blog, @article)  # => "http://foo.example.com/articles/lorem-ipsum"
```

### How it works

Subdomainify works by rewriting a subdomain URL to the specific route using a Rack middleware. In the above example, the resource URL for the `blogs` resource is located at `example.com/blogs/:id`. When users visit `foo.example.com`, Subdomainify will rewrite that request into `example.com/blogs/foo`. This includes everything else that was passed in as the path. For example, when users visit this URL:

```
http://foo.example.com/articles/hello-world
```

The middleware will rewrite `PATH_INFO` into:

```
http://foo.example.com/blogs/foo/articles/hello-world
```

Which means on the application side, you can treat subdomain routes like any other routes. Please note that even after rewriting, the subdomain is not discarded, allowing for its usage in constraints:

```ruby
constraints ->(req) { req.subdomain.present? } do
  resources :blogs, subdomainify: true do
    resources :articles
    resources :comments
  end
end
```

Doing so will make this route accessible only when visited from subdomain URL.

## License

Copyright (c) 2014, Oozou, Ltd. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
