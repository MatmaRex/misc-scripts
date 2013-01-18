# coding: utf-8
require 'sunflower'
require 'nokogiri'
#require 'memoize'
require 'io/console'

# RestClient.log = STDERR
$s = s = Sunflower.new('w:pl').login 'MatmaBot', STDIN.noecho{STDIN.gets.strip}
s.summary = 'konwersja formatu współrzędnych'
puts 'ok...'

#include Memoize
def the_list
	s = $s
	l = s.make_list 'whatembeds', 'Szablon:Koordynaty'
	l &= s.API('action=query&list=allpages&format=json&apfrom=Wiki%20Lubi%20Zabytki%2Fwykazy%2F&apto=Wiki%20Lubi%20Zabytki%2Fwykazy%2Fwszystkie&apnamespace=102&apfilterredir=nonredirects&aplimit=5000')['query']['allpages'].map{|a| a['title'] }
	l.to_a
end
#memoize :the_list, 'koord_cache2'

l = s.make_list 'pages', the_list

p l.length

# l = l.select{|a| a.start_with? 'Wikiprojekt:Wiki Lubi Zabytki/wykazy/województwo łódzkie/powiat poddębicki/'}
(s.make_list 'pages', l).pages_preloaded.each do |p|
	p.text.gsub!(/ *\| *koordynaty *= *(\{\{koordynaty[^{}\n]+\}\}) *(\s*[\|\}])/) do
		t, after = $1, $2
		expanded = s.API(action:'parse', text:t)['parse']['text']['*']
		coords = Nokogiri.HTML(expanded).css('.geo-dec').text
		lat, long = * coords.split(',').map{|a| a.strip}
		<<-EOF.gsub('		', '').strip + after
		| szerokość  = #{lat}
		| długość    = #{long}
		EOF
	end
	
	next if p.text == p.orig_text
	
	p.save
#	$ok=gets.strip=='ok' unless $ok
end
