require 'faraday'
require 'nokogiri'
require 'json'
require 'bunny'

class Scraper
  def initialize
    @queue = create_queue
    @conn  = create_conn
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

  def create_conn
    Faraday.new(:url => "http://www.builtincolorado.com/")
  end

  def self.scrape
    scraper = Scraper.new
    scraper.scrape_and_publish_jobs_to_queue(0)
  end

  def scrape_and_publish_jobs_to_queue(page_index)
    job_urls = job_urls_from_specific_page(page_index)

    job_urls.each do |url|
      job = scrape_job_page(url)
      @queue.publish(job)
    end
  end

  def job_urls_from_specific_page(page_index)
    page = @conn.get 'jobs#/jobs', { :page => page_index}
    parsed_page = Nokogiri::HTML(page.body)
    links = parsed_page.css('.job-title a').map { |link| link['href'] }
  end

  def job_urls_through_all_pages
    all_job_urls = []
    37.times do |i|
      all_job_urls << job_urls_from_specific_page(i)
      puts "one page down, #{37 - i} to go"
    end
    all_job_urls.flatten!
    puts all_job_urls
  end

  def scrape_job_page(link)
    page = @conn.get link
    parsed_page = Nokogiri::HTML(page.body)
    job = {
      title: parsed_page.css('.nj-job-title').text.strip,
      company: parsed_page.css('.nc-fallback-title').text.strip,
      description: parsed_page.css('.nj-job-body').to_html,
      url: "http://www.builtincolorado.com#{link}",
    }
    job.to_json
  end
end

Scraper.scrape
