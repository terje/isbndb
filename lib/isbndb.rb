require 'net/http'
require 'rexml/document'
require 'cgi'
include REXML

module ISBNDb
  @@key = 'REPLACE_WITH_YOUR_ISBNDB_KEY'
  @@root_url = 'http://isbndb.com/api/'

  def self.__define_accessors
    class_variables.each do |v| 
      sym = v.to_s.delete("@").to_sym
      unless self.respond_to? sym
        module_eval <<-EOS, __FILE__, __LINE__
          def self.#{sym}
            value = if defined?(#{sym.to_s.upcase})
              #{sym.to_s.upcase}
            else
              @@#{sym}
            end
            if value.is_a?(Hash)
              value = (self.domain.nil? ? nil : value[self.domain]) || value.values.first
            end
            value
          end
        
          def self.#{sym}=(obj)
            @@#{sym} = obj
          end
        EOS
      end
    end
  end

  __define_accessors

  class DB
    # Returns a list of Authors matching the provided search string
    def self.authors(query)
      doc = Util::fetch_xml(Util::url('authors.xml', {:index1 => 'name', :value1 => query}))
      results = XPath.match(doc.root, 'AuthorList/AuthorData').collect do |node|
        Author.new(node.attributes['person_id'], node.text('Name').to_s)
      end
      {:results => results, :pagination => Util::pagination('AuthorList', doc)}
    end

    # Returns a list of books matching the given search query.  The search_key can
    # be one of: isbn, title, combined, full, book_id, person_id, publisher_id,
    # subject_id, dewey_decimal, lcc_number
    def self.books(search_key, query)
      doc = Util::fetch_xml(Util::url('books.xml', {:index1 => search_key, :value1 => query}))
      results = XPath.match(doc.root, "BookList/BookData").collect do |node|
        Book.new(node.attributes['book_id'],
                 node.text('Title'),
                 node.text('TitleLong'),
                 node.text('AuthorsText'),
                 node.text('PublisherText'),
                 node.attributes['isbn13'])
      end
      {:results => results, :pagination => Util::pagination('BookList', doc)}
    end

    # Match fetching books by a search key.  Can be used to call ISBNDb::DB::books by using
    # methods that are named after the search key.  Examples: ISBNDb::DB::books_by_isbn,
    # ISBNDb::DB::books_by_person_id.  This method understands the difference between books
    # and book and will return only the first match if the singular form is used.
    def self.method_missing(name, *args)
      if name.to_s =~ /^book(s?)_by_\w+$/
        # Fetch books using the provided search key
        books = self.books(name.to_s.gsub(/book(s?)_by_/, ''), args.first)
        if name.to_s =~ /^book_/
          # We only want a single book, so return the first one
          return books[:results].first
        else
          # Return all results
          return books
        end
      else
        # The method called didn't match anything we recognise.  Pass it on.
        super
      end
    end
  end

  class Util
    # Returns a URL to call the ISBNDb XML API.  Takes a path, such as authors.xml or
    # books.xml, and a hash of url parameters.  Documentation of URL parameters can be
    # found at http://isbndb.com/docs/api/
    def self.url(path, params)
      # Add the API key to the URL
      raise 'You need an API key at ISBNDb to use this gem' if ISBNDb::key.nil?
      params[:access_key] = ISBNDb::key
      URI.parse(ISBNDb::root_url + path + '?' + params.collect { |key, value| key.to_s + '=' + CGI.escape(value) }.join('&'))
    end

    # Returns the pagination parameters provided by the ISBNDb result
    def self.pagination(list_element_name, doc)
      list_element = doc.root.elements[list_element_name]
      {
        :total_results => list_element.attributes['total_results'],
        :page_size => list_element.attributes['page_size'],
        :page_number => list_element.attributes['page_number'],
        :shown_results => list_element.attributes['shown_results']
      }
    end

    # Fetch a resource from the ISBNDb API and parse the returned data as an XML document
    def self.fetch_xml(url)
      # TODO: Error handling
      request = Net::HTTP::Get.new(url.path + '?' + url.query, Util::headers)
      response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }
      Document.new(response.body)
    end

    def self.headers
      { "User-Agent" => "Ruby v1.9.1" }
    end
  end

  class Author < Struct.new(:author_id, :name); end
  class Book < Struct.new(:book_id, :title, :title_long, :author, :publisher, :isbn13); end
end
