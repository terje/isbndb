require 'net/http'
require 'rexml/document'
require 'cgi'
include REXML

class ISBNDb
  attr_reader :key
  ROOTURL = 'http://isbndb.com/api/'

  def initialize(key)
    @key = key
  end

  def authors(q)
    url = self.url(ROOTURL + 'authors.xml', {:index1 => 'name', :value1 => q})
    request = Net::HTTP::Get.new(url.path + '?' + url.query, headers)
    response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }
    doc = Document.new(response.body)

    XPath.match(doc.root, 'AuthorList/AuthorData').collect do |node|
      [node.attributes['person_id'], node.text('Name').to_s] 
    end
  end

  def method_missing(name, *args)
    super unless name.to_s =~ /^book(s?)_by_\w+$/
    books(name.to_s.gsub(/book(s?)_by_/, ''), args.first)
  end

  def books(key, q)
    url = self.url(ROOTURL + 'books.xml', {:index1 => key, :value1 => q})
    request = Net::HTTP::Get.new(url.path + '?' + url.query, headers)
    response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }
    doc = Document.new(response.body)

    XPath.match(doc.root, "BookList/BookData").collect do |node|
      {
        :title => node.text('Title'),
        :title_long => node.text('TitleLong'),
        :author => node.text('AuthorsText')
      }
    end
  end

  def headers
    {
      "User-Agent" => "Ruby v1.9.1"
    }
  end

  def url(url, params)
    params[:access_key] = @key
    URI.parse(url + '?' + params.collect { |key, value| key.to_s + '=' + CGI.escape(value) }.join('&'))
  end
end
