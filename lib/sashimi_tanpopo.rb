# frozen_string_literal: true

require "logger"
require "diffy"
require "octokit"
require "gitlab"

require_relative "sashimi_tanpopo/version"
require_relative "sashimi_tanpopo/file_updater"
require_relative "sashimi_tanpopo/logger"
require_relative "sashimi_tanpopo/provider"

module SashimiTanpopo
  class Error < StandardError; end
  # Your code goes here...
end
