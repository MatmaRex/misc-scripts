# coding: utf-8

require 'sunflower'

meta = Sunflower.new 'meta'
sites = meta.API('action=sitematrix&smlimit=max')['sitematrix']
sites.delete 'count'
sites = sites.delete('specials') + sites.values.map{|a| a['site'] }.inject(:+)

# sites = [{'url' => 'w:pl'}]

sites.each do |hash|
	next if hash['closed'] || hash['private'] || hash['fishbowl']
	next if hash['dbname'].start_with? 'login'
	
	print "#{hash['url'].sub %r|^https?://|, ''}: "
	
	s = Sunflower.new hash['url']
	p = s.page 'MediaWiki:mainpage'
	hascustom = p.text != ''
	
	messagecontents = s.API('action=query&meta=allmessages&ammessages=mainpage')
	messagecontents = messagecontents['query']['allmessages'][0]['*']
	
	puts hascustom ? "CUSTOM #{messagecontents}" : 'DEFAULT'
end