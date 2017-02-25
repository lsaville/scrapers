require 'nokogiri'
require 'faraday'
require 'json'
require 'bunny'
require 'pry'


class StackOverflowScraper
  attr_reader :queue, :conn

  def initialize
    @queue = create_queue
    @conn = Faraday.new("http://stackoverflow.com/jobs/feed")
  end

  def create_queue
    connection = Bunny.new(
      :host => 'monocle.turing.io',
      :port => '5672',
      :user => 'monocle',
      :pass => 'RzoCoV7GR2wGAb'
    )
    connection.start
    channel = connection.create_channel
    channel.queue('scrapers.to.lookingfor')
  end

  def scrape
    feed = pull_feed
    if feed
      format_entries(feed)
    end
  end

  def pull_feed
    Nokogiri::HTML(conn.get.body)
  end

  def format_entries(entries)
    entries.css('item').map do |entry|
      formatted_entry = format_entry(entry)
      push_to_queue(formatted_entry)
    end
  end

  def push_to_queue(entry)
    queue.publish(entry.to_json)
  end

  def format_entry(entry)
    title = entry.css('title').text
    url_address = entry.css('guid').text
    location = entry.css('location').text
    description = entry.css('description').text
    
    { job: {
        title: title,
        url: url_address,
        old_location: location,
        raw_technologies: generate_raw_technologies(entry), #["perl", "python", "ruby", "or-go.-ruby-and", "or-go-experience-is-stron"],
        description: description,
        remote: is_remote?(title),
        posted_date: entry.css('pubdate').text
      },
      company: {
        name: pull_company_name(title)
      },
      location: {
        name: location
      }
    }
  end

  def pull_company_name(title)
    regex = /at (.*?) \(/
    regex.match(title)[1] rescue ''
  end

  def pull_location(title)
    regex = /\((.*?)\)/
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
