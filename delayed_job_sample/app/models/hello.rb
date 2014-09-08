class Hello < ActiveRecord::Base
  def self.say_hello(message)
    sleep 5
    logger = Logger.new(File.join(Rails.root, 'log', 'delay.log'))
    logger.info "Hello #{message}"
  end
end
