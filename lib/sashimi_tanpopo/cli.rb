# frozen_string_literal: true

require "thor"
require "sashimi_tanpopo"

module SashimiTanpopo
  class CLI < Thor
    def self.define_common_options
      option :target_dir, type: :string, aliases: "-d", default: Dir.pwd, desc: "Target directory"
      option :params, type: :string, aliases: "-p", desc: "Params passed to recipe file", banner: "key=value", repeatable: true
      option :dry_run, type: :boolean, default: false, desc: "Whether to run dry run"
      option :color, type: :boolean, default: true, desc: "Whether to colorize output"
    end

    desc "local RECIPE [RECIPE...]", "Change local files using recipe files"
    define_common_options
    def local(*recipe_files)
    end
  end
end
