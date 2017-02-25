require_relative 'publisher'
require 'faraday'
require 'json'

class GithubScraper
  attr_reader :publisher

  def initialize
    @publisher = Publisher.new
  end

  def fetch_jobs
    jobs = []
    page = 0
    loop do
      response = get_jobs(page)
      page += 1
      jobs << response unless response.empty?
      break if response.empty?
    end
    send_jobs(jobs.flatten)
  end

  private

    def get_jobs(page)
      response = Faraday.get("https://jobs.github.com/positions.json?page=#{page}")
      JSON.parse(response.body, symbolize_names: true)
    end

    def send_jobs(jobs)
      jobs.each { |job|  publisher.publish(format_job(job)) }
    end

    def format_job(job)
      { job: {
          id: job[:id],
          title: job[:title],
          description: job[:description],
          url: job[:url],
          posted_date: job[:created_at],
        },
        company: {
          name: job[:company]
        },
        location: {
          name: job[:location]
        }
      }
    end
end

GithubScraper.new.fetch_jobs
