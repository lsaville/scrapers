require_relative('technologies_module')
require_relative('base_scraper_module')

class WeWorkRemotelyScraper
  include Technologies, BaseScraper
  attr_reader :queue, :conn

  def initialize
    @queue = BaseScraper.create_queue
    @conn = Faraday.new("https://weworkremotely.com/categories/2-programming/jobs.rss")
  end

  DIVS_OR_LIS        = /<\/div>|<li>/
  NONBREAKING_SPACES = /&nbsp;/
  NEWLINES_OR_TABS   = /\n+|\t+/
  ESCAPED_QUOTES     = "\""



  def format_entries(entries)
    entries.css('item').map do |entry|
      formatted_entry = format_entry(entry)
      push_to_queue(formatted_entry)
    end
  end

  def push_to_queue(entry)
    queue.publish(entry.to_json)
  end

  def pull_feed
    Nokogiri::HTML(conn.get.body)
  end

  def format_entry(entry)
    title = entry.css('title').text
    url_address = entry.css('guid').text
    description = entry.css('description').text
    location = pull_location(description)
    posted_date = entry.css('pubdate').text
    technologies = pull_technologies(description)
    company_name = pull_company_name(title)

    { job: {
        title: title,
        url: url_address,
        raw_technologies: technologies,
        description: description,
        remote: true,
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


  def strip_summary(summary)
    summary = summary.gsub(DIVS_OR_LIS, " ").gsub(NONBREAKING_SPACES,"")
    Nokogiri::HTML(summary).text
  end

  def pull_location(summary)
    regex = /Headquarters: (.*)\s* URL/

    regex.match(summary)[1] rescue ''
  end

  def pull_technologies(description)
    Technologies.technologies_list.select do |tech|
      regex = /\b#{tech}\b/i
      regex.match(description)
    end
  end

  def pull_company_name(title)
    regex = /(.*):/
    regex.match(title)[1] rescue ''
  end

  def pull_description(summary)
    description = summary.split("\n\n\n")[-2]
    scrub_description(description)
  end

  def scrub_description(description)
    description.gsub(NEWLINES_OR_TABS, " ").gsub(ESCAPED_QUOTES, "'").split.join(" ").strip
  end

end


WeWorkRemotelyScraper.new.scrape
