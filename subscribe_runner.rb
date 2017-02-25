require 'bunny'

connection = Bunny.new(
  :host => 'monocle.turing.io',
  :port => '5672',
  :user => 'monocle',
  :pass => 'RzoCoV7GR2wGAb'
)
connection.start
channel = connection.create_channel
queue = channel.queue('scrapers.to.lookingfor')

queue.subscribe do |delivery_info, metadata, payload|
  puts "#{payload}"
end

loop do

end
