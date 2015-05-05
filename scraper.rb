#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'open-uri/cached'
require 'colorize'
require 'pry'
require 'csv'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

@WIKI = 'http://en.wikipedia.org'

def wikilink(a)
  return if a.attr('class') == 'new' 
  @WIKI + a['href']
end

@terms = {
  '24' => "24th_Parliament_of_Turkey",
  '23' => "23rd_Parliament_of_Turkey",
  '22' => "22nd_Parliament_of_Turkey",
  '21' => "21st_Parliament_of_Turkey",
  '20' => "20th_Parliament_of_Turkey",
}

@terms.each do |term, pagename|
  warn "Fetching #{term}"
  url = "#{@WIKI}/wiki/#{pagename}"
  page = noko(url)

  page.xpath('//table[.//th[text()[contains(.,"Member")]]]').each_with_index do |ct, i|
    next if ct.xpath('.//th[text()[contains(.,"Proportion")]]').any?
    district = ct.xpath('./preceding::h2[1]/span[@class="mw-headline"]').text 
    raise "No district found in #{ct}" if district.empty?
    ct.xpath('tr[td]').each do |member|
      tds = member.xpath('td')

      data = { 
        name: tds.first.at_xpath('a') ? tds.first.xpath('a').text.strip : tds.first.text.strip,
        wikipedia: tds.first.xpath('a[not(@class="new")]/@href').text.strip,
        party: tds.last.at_xpath('a') ? tds.last.xpath('a').text.strip : tds.last.text.strip,
        constituency: district,
        source: url,
        term: term,
      }
      data[:wikipedia].prepend @WIKI unless data[:wikipedia].empty?
      puts data.values.to_csv
      # ScraperWiki.save_sqlite([:name], data)
    end
  end
end

