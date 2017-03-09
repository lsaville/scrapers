require_relative('technologies_module')
require_relative('base_scraper_module')

class StackOverflowScraper
  include BaseScraper
  attr_reader :conn

  COMPANY_NAME_REGEX  = /at (.*?) \(/
  LOCATION_REGEX      = /\((.*?)\)/

  def initialize
    @conn = Faraday.new("http://stackoverflow.com/jobs/feed")
  end

  def scrape
    feed = BaseScraper.pull_feed(conn)
    if feed
      format_entries(feed)
    end
  end

  def format_entries(entries)
    entries.css('item').map do |entry|
      formatted_entry = format_entry(entry)
      BaseScraper.push_to_queue(formatted_entry)
    end
  end

  def format_entry(entry)
    title = entry.css('title').text

    BaseScraper.create_payload(title,
      entry.children[2].text,
      generate_raw_technologies(entry),
      entry.css('description').text,
      is_remote?(title),
      entry.css('pubdate').text,
      BaseScraper.pull_company_name(title, COMPANY_NAME_REGEX),
      entry.css('location').text

    )
  end

  def pull_location(title)
    regex =
    regex.match(title)[1] rescue ''
  end

  def is_remote?(title)
    /remote/i === title
  end

  private

  def generate_raw_technologies(entry)
    entry.css('category').map do |category|
      category.text
    end
  end

end

StackOverflowScraper.new.scrape
