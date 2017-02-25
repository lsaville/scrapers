require 'bunny'

class Publisher
  attr_reader :connection

  def initialize
    @connection = Bunny.new(
                            :host => "monocle.turing.io",
                            :port => "5672",
                            :user => "monocle",
                            :pass => "RzoCoV7GR2wGAb"
                            )
  end

  def publish(data)
    connection.start
    channel = connection.create_channel
    queue = channel.queue("scrapers.to.lookingfor")
    queue.publish(data.to_json)
  end
end
