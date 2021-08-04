require 'open-uri'
require 'nokogiri'

module NaganoCovid19AlertNotify
  URL = 'https://www.pref.nagano.lg.jp/kansensho-taisaku/kenko/kenko/kansensho/joho/corona-keniki.html'.freeze
  AREA = '長野'.freeze
  UPDATED_DATE_SELECTOR = 'p#tmp_update'.freeze
  TABLE_ROW_SELECTOR = 'table.datatable tbody tr'.freeze
  TABLE_HEADER_CELL_SELECTOR = 'th'.freeze
  TABLE_DATA_CELL_SELECTOR = 'td'.freeze

  class << self
    def run
      text_to_notify = create_text_to_notify
      puts text_to_notify
    end

    private

    def create_text_to_notify
      data = parse_url
      <<~TEXT
        #{AREA}圏域の新型コロナウイルス感染警戒レベルは#{data[:level]}です。
        感染警戒レベル：#{data[:level]}
        圏域人口　　　：#{data[:population]}
        件数　　　　　：#{data[:positives]}
        増減　　　　　：#{data[:increase_and_decrease]}
        人口10万人当たりの新規陽性者数：#{data[:positives_per_population]}
        (#{data[:updated_date]})
      TEXT
    end

    def parse_url
      doc = Nokogiri::HTML(URI.parse(URL).open)
      doc.css(TABLE_ROW_SELECTOR).each_with_object({}) do |tr, result|
        next unless tr.css(TABLE_HEADER_CELL_SELECTOR).text == AREA

        td = tr.css(TABLE_DATA_CELL_SELECTOR)
        set_result(result, td)
      end.merge({ updated_date: doc.css(UPDATED_DATE_SELECTOR).text })
    end

    def set_result(result, td)
      result[:level] = td[0].text
      result[:population] = td[1].text
      result[:positives] = td[2].text
      result[:increase_and_decrease] = td[3].text
      result[:positives_per_population] = td[4].text
    end
  end
end
