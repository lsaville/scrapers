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

end
