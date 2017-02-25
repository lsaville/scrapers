require 'nokogiri'
require 'faraday'
require 'json'
require 'bunny'
require 'pry'

module BaseScraper

  def self.create_queue
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

  def self.scrape
    feed = pull_feed
    if feed
      format_entries(feed)
    end
  end

  def self.pull_feed
    Nokogiri::HTML(conn.get.body)
  end

  def self.push_to_queue(entry)
    queue.publish(entry.to_json)
  end

  def self.create_payload(title,
    url_address,
    technologies,
    description,
    remote,
    posted_date,
    company_name,
    location
  )
    { job: {
        title: title,
        url: url_address,
        raw_technologies: technologies,
        description: description,
        remote: remote,
        posted_date: posted_date
      },
      company: {
        name: company_name
      },
      location: {
        name: location,
      }
    }
  end

end
