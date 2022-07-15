require "logger"

# logger

module Logging
  def logger_output(choice_of_output)
    Logger.new(choice_of_output,
    level: Logger::INFO,
    progname: "Lyrics-App",
    datetime_format: "%Y-%m-%d %H:%M:%S",
    formatter: proc do |severity, datetime, progname, msg|
      "[#{blue(progname)}][#{datetime}], #{severity}: #{msg}\n"
    end
    )
  end
end
