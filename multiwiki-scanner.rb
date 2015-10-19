# coding: utf-8

require 'sunflower'
require 'parallel'

meta = Sunflower.new 'meta'
sites = meta.API('action=sitematrix&smlimit=max')['sitematrix']
sites.delete 'count'
sites = sites.delete('specials') + sites.values.map{|a| a['site'] }.inject(:+)

# sites = [{'url' => 'w:pl'}]

$stdout.sync = true
# sites.each do |hash|
Parallel.each(sites, in_threads: 10) do |hash|
	begin
		next if hash['closed'] || hash['private'] || hash['fishbowl']
		next if hash['dbname'].start_with? 'login'
		
		out = "#{hash['url'].sub %r|^https?://|, ''}: "
		
		s = Sunflower.new hash['url']
		p = s.page 'MediaWiki:stub-threshold'
		hascustom = p.text != ''
		
		messagecontents = s.API('action=query&meta=allmessages&ammessages=stub-threshold')
		messagecontents = messagecontents['query']['allmessages'][0]['*']
		
		out << (hascustom ? "CUSTOM #{messagecontents}" : 'DEFAULT')
		
		print "#{out}\n"
	rescue
		$stderr.puts hash['url']
		$stderr.puts $!
		$stderr.puts $!.backtrace
	end
end
