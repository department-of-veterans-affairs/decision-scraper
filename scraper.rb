#!/usr/bin/env ruby

require 'uri'
require 'open-uri'  
require 'nokogiri'
require 'fileutils'

OUT_DIR = 'decisions'
YEARS = 1992..2016

# SHAME! SHAME! SHAME!
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def try_conn(url)
    count = 0
    begin
      yield
    rescue Errno::ECONNRESET => e
      count += 1
      retry unless count > 10
      puts "Couldn't retrieve #{url}: #{e}"
    end
end

for year in YEARS
    dir = "#{OUT_DIR}/#{year}"
    FileUtils.mkdir_p(dir)

    url = "http://www.index.va.gov/search/va/bva_search.jsp?QT=&EW=&AT=&ET=&RPP=50&DB=#{year}"

    offset = 1

    begin
        page_url = "#{url}&RS=#{offset}"
        puts "Downloading decisions from #{page_url}"
        doc = try_conn(page_url) do
            Nokogiri::HTML(open(page_url))
        end

        decision_urls = doc.css('#results-area a').collect { |a| a['href'] }

        for decision_url in decision_urls
            try_conn(decision_url) do
                file = open(decision_url)
                IO.copy_stream(file, "#{dir}/#{file.base_uri.to_s.split('/')[-1]}")
            end
        end

        offset += 50
    end while decision_urls.length > 0
end
