require 'helper'
require 'yaml'

class TestIsbndb < Test::Unit::TestCase
  context "ISBNDb" do
    setup do
      flunk 'Copy test/config-example.yml to test/config.yml and change the key to your own' unless File.exist?('test/config.yml')
      @apikey = YAML::load(File.open('test/config.yml'))['apikey']
      flunk 'Put your ISBNDb API key in test/config.yml to run these tests' if @apikey.nil?
      ISBNDb::key = @apikey
    end

    should 'store correct API key' do
      assert_equal ISBNDb::key, @apikey
    end

    should 'return a list of authors from a search query' do
      authors = ISBNDb::DB::authors('Dawkins, Richard')
      ISBNDb::DB::books_by_author('Dawkins, Richard')
      assert_kind_of authors, Array
      assert_operator authors.length, :>=, 1
      assert_kind_of authors.first, ISBNDb::Author
    end

    should 'return a single book result from an ISBN query' do
      book = ISBNDb::DB::book_by_isbn('9781416594789')
      assert_not_nil book
      assert_kind_of book, ISBNDb::Book
    end

    should 'return all books by a given author' do
      books = ISBNDb::DB::books_by_person_id(ISBNDb::DB::authors('Dawkins, Richard').first.first)
      assert_operator books.length, :>=, 1
    end

    should 'return first book by a given author' do
      book = ISBNDb::DB::book_by_person_id(ISBNDb::DB::authors('Dawkins, Richard').first.first)
      assert_kind_of book, ISBNDb::Book
    end
  end
end
