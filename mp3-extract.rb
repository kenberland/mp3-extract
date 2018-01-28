#!/usr/bin/env ruby
require 'bundler'
require 'net/http'
require 'json'
require 'pry'
require 'fileutils'
require 'nokogiri'

USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36'

def fetch(uri_str, limit = 10)
  puts "fetch:#{uri_str} #{limit}"
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0

  url = URI.parse(uri_str)
  base = "#{url.scheme}://#{url.host}"
  req = Net::HTTP::Get.new(url.path, {'User-Agent' =>  USER_AGENT}
                                     })
  response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
  case response
  when Net::HTTPSuccess
  then
    response
  when Net::HTTPRedirection
  then
    fetch(response['location'], limit - 1)
  else
    response.error!
  end
end

def parse(src)
  doc = Nokogiri::HTML(src)
  links = []
  doc.css('a').each do |link|
    url = link.attributes['href'].value rescue nil
    unless url.nil?
      re = /http:.*\.mp3$/.match(url)
      links.push(re[0]) if re
    end
  end
  return links
end

def download(links)
  links.each do |link|
    filename = URI.unescape(Pathname.new(URI(link).path).basename.to_s)
    res = fetch(link)
    fd = File.open(filename, 'w+')
    fd.write(res.body)
    fd.close
    puts "saved #{res.body.size} bytes #{filename}"
  end
end

res = fetch('http://www.bethelberkeley.org/learning/music/music-resources')
links = parse(res.body)
download(links)

