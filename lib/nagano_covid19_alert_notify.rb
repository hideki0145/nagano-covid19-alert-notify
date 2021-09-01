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
      if data_equal?(system_data, data)
        nil
      else
        save_system_data(data)
        I18n.t(
          'text_to_notify', area: data[:area], level: data[:level], population: data[:population],
                            positives: data[:positives], increase_and_decrease: data[:increase_and_decrease],
                            positives_per_population: data[:positives_per_population], updated_date: data[:updated_date]
        )
      end
    end

    def parse_url
      doc = Nokogiri::HTML(open_html)
      doc.css(CONFIG[:table_row_selector]).each_with_object({}) do |tr, result|
        next if other_area?(tr)

        th = tr.css(CONFIG[:table_header_cell_selector])
        td = tr.css(CONFIG[:table_data_cell_selector])
        set_result(result, th, td)
      end.merge({ updated_date: doc.css(CONFIG[:updated_date_selector]).text })
    end

    def open_html
      return File.new('./config/test.html') if CONFIG[:test]

      URI.parse(CONFIG[:url]).open
    end

    def use_slack_notification?(text_to_notify)
      !CONFIG[:slack_token].nil? && !CONFIG[:slack_channel].nil? && !text_to_notify.nil?
    end

    def other_area?(tr)
      tr.css(CONFIG[:table_area_cell_selector]).text.strip != CONFIG[:area]
    end

    def data_equal?(data1, data2)
      return false if CONFIG[:test]

      data1 == data2
    end

    def set_result(result, th, td)
      result[:area] = area(th)
      result[:level] = level(td)
      result[:population] = population(td)
      result[:positives] = positives(td)
      result[:increase_and_decrease] = increase_and_decrease(td)
      result[:positives_per_population] = positives_per_population(td)
    end

    def area(th)
      th.text.strip.gsub(/\R/, '').gsub(/\s/, '')
    end

    def level(td)
      td[0].text.strip.gsub(/\R/, '').gsub(/\s/, '')
    end

    def population(td)
      td[1].text.strip.gsub(/\R/, '')
    end

    def positives(td)
      td[2].text.strip.gsub(/\R/, '')
    end

    def increase_and_decrease(td)
      td[3].text.strip.gsub(/\R/, '')
    end

    def positives_per_population(td)
      td[4].text.strip.gsub(/\R/, '')
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
