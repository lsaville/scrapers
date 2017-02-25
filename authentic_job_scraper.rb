require 'faraday'
require 'json'
require 'pry'
require 'bunny'
require './secrets'

class AuthenticScraper
  extend Secrets

  def initialize
    @queue = create_queue
    @conn = create_conn
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

  def self.fetch_jobs
    jobs = []
    number = 0
    loop do
      response = get_jobs(number)
      number += 1
      jobs << response unless response.empty?
      break if response.empty?
    end
    send_jobs(jobs.flatten)
  end

  private

  # def self.get_jobs(number)
  #   response = Faraday.get("https://jobs.github.com/positions.json?page=#{number}")
  #   JSON.parse(response.body, symbolize_names: true)
  # end
  #
  # def self.send_jobs(jobs)
  #   jobs.each { |job|  Publisher.new.publish(format_job(job)) }
  # end

  def self.format_job(job)
    {
      id: job[:id],
      title: job[:title],
      description: job[:description],
      url: job[:url],
      location: job[:location],
      posted_date: job[:created_at],
      company: job[:company],
    }
  end

  def self.get_jobs(term)
    response = self.parse(connect_to_authentic_jobs.get("?keywords=#{term}"))
    binding.pry
  end

  def self.connect_to_authentic_jobs
    connection = self.initial_connection
    connection.params['api_key'] = Secrets.authentic_jobs_key
    connection.params['format'] = 'json'
    connection.params['method'] = 'aj.jobs.search'
    connection.params['perpage'] = '100'
    connection
  end

  def self.initial_connection
    Faraday.new(url: "https://authenticjobs.com/api/")
  end

  def self.parse(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def self.scrape(term)
    jobs = self.get_jobs(term)
  end
end

AuthenticScraper.scrape("ruby")
