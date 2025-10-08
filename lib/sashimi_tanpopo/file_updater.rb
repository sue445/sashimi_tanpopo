# frozen_string_literal: true

module SashimiTanpopo
  class FileUpdater
    # @!attribute [r] params
    # @return [Hash<Symbol, String>]
    attr_reader :params

    # @param params [Hash<Symbol, String>]
    def initialize(params:)
      @params = params
    end

    # @param body [String]
    # @return [String]
    def evaluate(body)
    end
  end
end
