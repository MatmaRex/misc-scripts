# coding: utf-8
require 'io/console'

require 'sunflower'
require './infobox parser/infobox parser'

s = Sunflower.new('pl.wikipedia.org').login 'MatmaBot', STDIN.noecho{STDIN.gets.strip}
s.summary = 'bezpośrednie podanie kodu mapy lokalizacyjnej, [[WP:SK]]'

INFOBOX = "PRT gmina"

l = s.make_list 'whatembeds', 'Szablon:Mapa lokalizacyjna/Zgaduj mapę'
l &= s.make_list 'whatembeds', "Szablon:#{INFOBOX} infobox"

p l.length
#puts l.first 20

fmt = '{{Mapa lokalizacyjna/Zgaduj mapę|PT-30|PT-20|PRT|szerokość={{Koordynaty/zamień-kątowe-na-dziesiętne/prosty|N|{{{stopniN}}}|{{{minutN|0}}}|{{{sekundN|0}}}}}|długość={{Koordynaty/zamień-kątowe-na-dziesiętne/prosty|W|{{{stopniW}}}|{{{minutW|0}}}|{{{sekundW|0}}}}}}}'
# {{#ifexist:Szablon:Państwo dane {{{państwo}}}
# |{{mapa|{{{państwo}}}}}
# |{{{państwo}}}
# }}

require 'pp'

# l = l.first 3
l.sort.each do |t|
	puts t
	p = Sunflower::Page.new t
	
	ibt = Infobox.extract_ib_from_text p.text, INFOBOX
	# puts ibt
	next if !ibt
	
	ib = Infobox.parse ibt
	# pp ib
	next unless !ib['kod mapy'] || ib['kod mapy'].empty?
	# ib['państwo'] = ib['państwo'].strip.sub(/\A\{\{(?:państwo|flaga)\|([^}|]+)\}\}\Z/i, '\1')
	
	# nie wpisujemy danych bez sensu
	next if ib.values_at(*%w[stopniN stopniE stopniS stopniW stopniNS stopniEW]).join.strip == ''
	
	wikitext = fmt.dup
	ib.each_pair{|k,v| wikitext.gsub!(/{{{#{k}(?:\|.*?)?}}}/, v.strip) }
	
	# puts wikitext
	
	out = (s.API "action=expandtemplates&text=#{CGI.escape wikitext}")['expandtemplates']['*']
	ib['kod mapy'] = out.strip
	
	p.replace ibt, ib.pretty_format
	p.code_cleanup
	p.save
end



