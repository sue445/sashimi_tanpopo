# frozen_string_literal: true

module SashimiTanpopo
  module Logger
    class Formatter
      # @param severity [String]
      # @param datetime [Time]
      # @param progname [String]
      # @param msg [String]
      def call(severity, datetime, progname, msg)
        log = "%s : %s" % ["%5s" % severity, msg.strip]

        log + "\n"
      end
    end
  end

  @logger = ::Logger.new($stdout).tap do |l|
    l.formatter = SashimiTanpopo::Logger::Formatter.new
  end
  $stdout.sync = true

  class << self
    # @return [::Logger]
    def logger
      @logger
    end

    # @param l [::Logger]
    def logger=(l)
      @logger = l
    end
  end
end
