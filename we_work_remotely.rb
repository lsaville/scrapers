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
      BaseScraper.push_to_queue(formatted_entry)
    end
  end

  def format_entry(entry)
    BaseScraper.create_payload(entry.css('title').text,
      entry.css('guid').text,
      pull_technologies(description),
      entry.css('description').text,
      true,
      entry.css('pubdate').text,
      pull_company_name(title),
      pull_location(description)
    )
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
