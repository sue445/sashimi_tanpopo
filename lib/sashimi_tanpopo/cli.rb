# frozen_string_literal: true

require "thor"
require "sashimi_tanpopo"

module SashimiTanpopo
  class CLI < Thor
    desc "version", "Show sashimi_tanpopo version"
    def version
      puts "sashimi_tanpopo v#{SashimiTanpopo::VERSION}"
    end

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

    # @param params [Array<String>]
    # @return [Hash<String,String>]
    #
    # @example
    #   parse_params(["k1=v1", "k2=v2"])
    #   #=> {"k1"=>"v1", "k2"=>"v2"}
    def self.parse_params(params)
      params.map { |param| param.split("=", 2) }.to_h.transform_keys(&:to_sym)
    end
  end
end
