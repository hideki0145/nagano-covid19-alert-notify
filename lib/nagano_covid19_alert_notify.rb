require 'yaml'
require 'i18n'
require 'open-uri'
require 'nokogiri'

module NaganoCovid19AlertNotify
  CONFIG = YAML.load_file('./config/config.yml').transform_keys(&:to_sym).freeze
  I18n.load_path << Dir["#{File.expand_path('./config/locales')}/*.yml"]
  I18n.default_locale = CONFIG[:locale].to_sym

  class << self
    def run
      text_to_notify = create_text_to_notify
      if use_slack_notification?(text_to_notify)
        slack_notification(text_to_notify)
      else
        puts text_to_notify
      end
    end

    private

    def slack_notification(text_to_notify)
      uri = URI.parse('https://slack.com/api/chat.postMessage')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(
        token: CONFIG[:slack_token],
        channel: CONFIG[:slack_channel],
        text: text_to_notify
      )
      http.request(req)
    end

    def create_text_to_notify
      system_data = load_system_data
      data = parse_url
      if system_data == data
        nil
      else
        save_system_data(data)
        I18n.t(
          'text_to_notify', area: CONFIG[:area], level: data[:level], population: data[:population],
                            positives: data[:positives], increase_and_decrease: data[:increase_and_decrease],
                            positives_per_population: data[:positives_per_population], updated_date: data[:updated_date]
        )
      end
    end

    def parse_url
      doc = Nokogiri::HTML(URI.parse(CONFIG[:url]).open)
      doc.css(CONFIG[:table_row_selector]).each_with_object({}) do |tr, result|
        next if other_area?(tr)

        td = tr.css(CONFIG[:table_data_cell_selector])
        set_result(result, td)
      end.merge({ updated_date: doc.css(CONFIG[:updated_date_selector]).text })
    end

    def use_slack_notification?(text_to_notify)
      !CONFIG[:slack_token].nil? && !CONFIG[:slack_channel].nil? && !text_to_notify.nil?
    end

    def other_area?(tr)
      tr.css(CONFIG[:table_header_cell_selector]).text != CONFIG[:area]
    end

    def set_result(result, td)
      result[:level] = td[0].text
      result[:population] = td[1].text
      result[:positives] = td[2].text
      result[:increase_and_decrease] = td[3].text
      result[:positives_per_population] = td[4].text
    end

    SYSTEM_DATA_PATH = './config/system_data.yml'.freeze
    def load_system_data
      File.open(SYSTEM_DATA_PATH, 'w') unless File.exist?(SYSTEM_DATA_PATH)
      File.open(SYSTEM_DATA_PATH, 'r') { |f| YAML.safe_load(f) }&.transform_keys(&:to_sym)
    end

    def save_system_data(data)
      YAML.dump(data.transform_keys(&:to_s), File.open(SYSTEM_DATA_PATH, 'w'))
    end
  end
end
