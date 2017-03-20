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

def download_results(url, offset, dir)
    doc = Nokogiri::HTML(open("#{url}&RS=#{offset}"))

    decision_urls = doc.css('#results-area a').collect { |a| a['href'] }

    return if decision_urls.length == 0

    for decision_url in decision_urls
        file = open(decision_url)
        IO.copy_stream(file, "#{dir}/#{file.base_uri.to_s.split('/')[-1]}")
    end

    download_results(url, offset + 50, dir)
end

for year in YEARS
    dir = "#{OUT_DIR}/#{year}"
    FileUtils.mkdir_p(dir)

    url = "http://www.index.va.gov/search/va/bva_search.jsp?QT=&EW=&AT=&ET=&RPP=50&DB=#{year}"
    download_results(url, 1, dir)
end
