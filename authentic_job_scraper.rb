require 'faraday'
require 'json'
require 'pry'
require 'bunny'
require './secrets'
require './technologies_module'

class AuthenticScraper
  extend Secrets
  include Technologies

  def initialize
    @queue = create_queue
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

  def self.scrape
    scraper = AuthenticScraper.new
    scraper.fetch_jobs
  end

  def fetch_jobs
    jobs = []
    number = 1
    loop do
      response = get_jobs(number)
      number += 1
      jobs << response[:listings][:listing] unless response.empty?
      break if response[:listings][:listing].count < 100
    end
    send_jobs(jobs.flatten)
  end

  private

  def pull_technologies(description)
    Technologies.technologies_list.select do |tech|
      regex = /\b#{tech}\b/i
      regex.match(description)
    end
  end

  def format_job(job)
    location_name = job[:company][:location][:name] if job[:company][:location]
    { job: {
        title: job[:title],
        url: job[:url],
        raw_technologies: pull_technologies(job[:description]),
        description: job[:description],
        published: job[:post_date]
      },
      company: {
        name: job[:company][:name]
      },
      location: {
        name: location_name
      }
    }
  end

  def get_jobs(number)
    response = parse(connect_to_authentic_jobs.get("?page=#{number}"))
  end

  def connect_to_authentic_jobs
    connection = initial_connection
    connection.params['api_key'] = Secrets.authentic_jobs_key
    connection.params['format'] = 'json'
    connection.params['method'] = 'aj.jobs.search'
    connection.params['perpage'] = '100'
    connection
  end

  def initial_connection
    Faraday.new(url: "https://authenticjobs.com/api/")
  end

  def parse(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def send_jobs(jobs)
    jobs.each { |job|  publish_data(format_job(job)) }
  end

  def publish_data(data)
    binding.pry
    @queue.publish(data.to_json)
  end
end

AuthenticScraper.scrape
