require_relative('technologies_module')
require_relative('base_scraper_module')

class WeWorkRemotelyScraper
  include Technologies, BaseScraper
  attr_reader :conn

  DIVS_OR_LIS        = /<\/div>|<li>/
  NONBREAKING_SPACES = /&nbsp;/
  NEWLINES_OR_TABS   = /\n+|\t+/
  ESCAPED_QUOTES     = "\""
  HEADQUARTERS_REGEX = /Headquarters: (.*)\s* URL/
  COMPANY_NAME_REGEX = /(.*):/

  def initialize
    @conn = Faraday.new("https://weworkremotely.com/categories/2-programming/jobs.rss")
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
    description = entry.css('description').text
    title = entry.css('title').text

    BaseScraper.create_payload(title,
      entry.css('guid').text,
      pull_technologies(description),
      description,
      true,
      entry.css('pubdate').text,
      BaseScraper.pull_company_name(title, COMPANY_NAME_REGEX),
      BaseScraper.pull_location(description, HEADQUARTERS_REGEX)
    )
  end

  def strip_summary(summary)
    summary = summary.gsub(DIVS_OR_LIS, " ").gsub(NONBREAKING_SPACES,"")
    Nokogiri::HTML(summary).text
  end

  def pull_technologies(description)
    Technologies.technologies_list.select do |tech|
      regex = /\b#{tech}\b/i
      regex.match(description)
    end
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
