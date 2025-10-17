RSpec.shared_context :stub_logger do
  let(:log_output) { StringIO.new }

  around do |example|
    original_logger = SashimiTanpopo.logger

    SashimiTanpopo.logger = ::Logger.new(log_output).tap do |l|
      l.formatter = SashimiTanpopo::Logger::Formatter.new
    end

    example.run
  ensure
    SashimiTanpopo.logger = original_logger
  end
end
