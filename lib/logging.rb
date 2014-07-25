module Logging
  def logger
    @logger ||= Logging.logger_for(self.class.name)
  end

  @@global_level = Logger::INFO
  @@loggers = {}

  class << self
    def logger_for(classname)
      @@loggers[classname] ||= configure_logger_for(classname)
    end

    def configure_logger_for(classname)
      logger = Logger.new(STDOUT)
      logger.level = @@global_level
      logger.progname = classname
      logger
    end

    def global_level=(level)
      @@global_level = level
      @@loggers.each { |classname,logger| logger.level = level }
    end
  end
end
