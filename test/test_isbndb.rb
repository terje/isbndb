require 'helper'

class TestIsbndb < Test::Unit::TestCase
  context "A User instance" do
    APIKEY = 'XXXXXXXX'

    setup do
      @isbndb = ISBNDb.new(APIKEY)
    end

    should 'store correct API key' do
      assert_equal @isbndb.key, APIKEY
    end

    should 'return a list of authors from a search query' do
      authors = @isbndb.authors('Dawkins, Richard')
      assert_kind_of authors, Array
      assert_operator authors.length, :>=, 1
    end

    should 'return a single book result from an ISBN query' do
      book = @isbndb.book_by_isbn('9781416594789')
      assert_not_nil book
      assert_operator book.length, :==, 1
    end

    should 'return all books by a given author' do
      authors = @isbndb.authors('Dawkins, Richard')
      books = @isbndb.books_by_person_id(authors.first.first)
      assert_operator books.length, :>=, 1
    end
  end
end
