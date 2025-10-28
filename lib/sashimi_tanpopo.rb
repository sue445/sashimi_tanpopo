# frozen_string_literal: true

require "logger"
require "diffy"
require "octokit"
require "gitlab"
require "parallel"

require_relative "sashimi_tanpopo/version"
require_relative "sashimi_tanpopo/dsl"
require_relative "sashimi_tanpopo/logger"
require_relative "sashimi_tanpopo/provider"
require_relative "sashimi_tanpopo/diff_helper"

module SashimiTanpopo
  class Error < StandardError; end

  class NotFoundUserError < Error; end
end
