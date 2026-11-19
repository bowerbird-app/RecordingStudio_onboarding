# frozen_string_literal: true

module RecordingStudioOnboarding
  module SetupRecord
    OPTIONAL_FIELDS = %i[next_step icon link].freeze
    KNOWN_FIELDS = (%i[key] + OPTIONAL_FIELDS).freeze

    module_function

    def build(status, only:, except:, url_options:)
      fields = item_fields(only, except)
      options = url_options || default_url_options
      raise ArgumentError, "url_options must be a Hash" unless options.is_a?(Hash)

      heading(status).merge(lists(status, fields, options))
    end

    def heading(status)
      {
        "checklist" => status.checklist.to_s,
        "title" => status.title,
        "subtitle" => status.subtitle,
        "applicable" => status.applicable?,
        "complete" => status.complete?
      }
    end

    def lists(status, fields, options)
      {
        "remaining" => status.remaining.map { |item| item_record(item, fields, options) },
        "done" => status.done.map { |item| item_record(item, fields, options) }
      }
    end

    def item_fields(only, except)
      only_names = names(only)
      except_names = names(except) || []
      reject_unknown(Array(only_names) + except_names)
      raise ArgumentError, "key is always included" if except_names.include?(:key)

      chosen = only_names.nil? ? OPTIONAL_FIELDS : (only_names & OPTIONAL_FIELDS)
      chosen - except_names
    end

    def reject_unknown(names)
      unknown = names - KNOWN_FIELDS
      return if unknown.empty?

      raise ArgumentError, "unknown item field #{unknown.map(&:inspect).join(', ')}"
    end

    def names(value)
      return if value.nil?

      Array(value).map(&:to_sym)
    end

    def item_record(item, fields, url_options)
      record = { "key" => item.key.to_s }
      record["next_step"] = item.next_step if fields.include?(:next_step)
      record["icon"] = item.icon.to_s if fields.include?(:icon)
      record["link"] = absolute_link(item.link, url_options) if fields.include?(:link)
      record
    end

    def absolute_link(link, url_options)
      return if link.nil?
      return link if link.match?(ChecklistItem::ABSOLUTE_HTTP)

      host = option(url_options, :host)
      return link if host.blank?

      "#{protocol_for(url_options)}://#{host}#{port_suffix(url_options)}#{link}"
    end

    def protocol_for(url_options)
      protocol = option(url_options, :protocol).to_s.sub(%r{://\z}, "")
      protocol.empty? ? "http" : protocol
    end

    def port_suffix(url_options)
      port = option(url_options, :port)
      protocol = protocol_for(url_options)
      return "" if port.blank? || standard_port?(protocol, port.to_i)

      ":#{port}"
    end

    def option(url_options, name)
      url_options[name] || url_options[name.to_s]
    end

    def standard_port?(protocol, port)
      (protocol == "https" && port == 443) || (protocol == "http" && port == 80)
    end

    def default_url_options
      return {} unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

      Rails.application.routes.default_url_options || {}
    end
  end
end
