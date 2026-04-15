ENV['OTEL_RUBY_INSTRUMENTATION_GROUP_DB_STATEMENT'] = 'include'
ENV['OTEL_RUBY_INSPECT_VALUE_LENGTH'] = '2048'
ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = 'http://xxx:4318'
# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'rails8_demo'
  # c.add_span_processor(
    # OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      # OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
    # )
  # )
  c.use_all()
end

