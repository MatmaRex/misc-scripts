# coding: utf-8

require 'nokogiri'
require 'cgi'
require 'sunflower'
require 'parallel'

meta = Sunflower.new 'meta'
sites = meta.API('action=sitematrix&smlimit=max')['sitematrix']
sites.delete 'count'
sites = sites.delete('specials') + sites.values.map{|a| a['site'] }.inject(:+)

search = %|insource:/\\<gallery widths=["']?[0-9]+[^0-9p"' >]/|

$stdout.sync = true
# sites.each do |hash|
Parallel.each(sites, in_threads: 10) do |hash|
	begin
		next if hash['closed'] || hash['private'] || hash['fishbowl']
		next if hash['dbname'].start_with? 'login'
		
		url = "#{hash['url']}/w/index.php?search="+CGI.escape(search)
		html = RestClient.get url rescue next
		noko = Nokogiri.HTML html
		# p noko.css('.results-info strong')
		# puts url
		count = noko.css('.results-info strong')[-1].text rescue 0
		
		print "#{count}	#{url}\n" unless count == 0
	rescue
		$stderr.puts hash['url']
		$stderr.puts $!
		$stderr.puts $!.backtrace
	end
end
