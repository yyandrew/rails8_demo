ENV['OTEL_RUBY_INSTRUMENTATION_GROUP_DB_STATEMENT'] = 'include'
ENV['OTEL_RUBY_INSPECT_VALUE_LENGTH'] = '2048'
ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = 'http://xxx:4318'
# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry-exporter-otlp'

module SqlSpanCallsiteAnnotator
  extend self

  APP_CODE_ROOTS = %w[app lib].map { |dir| Rails.root.join(dir).to_s.freeze }.freeze
  APP_ROOT = Rails.root.to_s.freeze
  IGNORE_PATH_FRAGMENTS = [
    '/gems/',
    '/ruby/',
    '/config/initializers/opentelemetry.rb'
  ].freeze

  def install!
    ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
      next if payload[:name] == 'SCHEMA'

      span = OpenTelemetry::Trace.current_span
      next unless span.context.valid?
      next if span_attribute?(span, 'code.filepath')

      location = find_callsite
      next unless location

      span.set_attribute('code.filepath', location.path)
      span.set_attribute('code.lineno', location.lineno)
      span.set_attribute('code.function', location.base_label) if location.base_label
      span.set_attribute('rails.sql.caller', "#{location.path}:#{location.lineno}")
    end
  end

  private

  def span_attribute?(span, key)
    span.respond_to?(:attributes) && span.attributes&.key?(key)
  end

  def find_callsite
    locations = caller_locations(2, 40)
    locations.find { |location| app_code_path?(location.path) } ||
      locations.find { |location| project_path?(location.path) }
  end

  def app_code_path?(path)
    APP_CODE_ROOTS.any? { |root| path.start_with?(root) }
  end

  def project_path?(path)
    path.start_with?(APP_ROOT) && IGNORE_PATH_FRAGMENTS.none? { |fragment| path.include?(fragment) }
  end
end

SqlSpanCallsiteAnnotator.install!
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'rails8_demo'
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
    )
  )
  c.use_all
end

