# coding: utf-8

require_relative 'infobox parser'
require 'sunflower'


s = Sunflower.new.login
s.summary = 'zmiana nazwy + standaryzacja infoboksu {{[[Szablon:Projekt Fundacji Wikimedia infobox|Projekt Fundacji Wikimedia infobox]]}}, [[WP:SK]]'

t = 'Wikiprojekt infobox'
params_r = Infobox.parse('{{Wikiprojekt infobox|wikiprojekt=|logo=|data uruchomienia=|artykułów=|użytkowników=|administratorów=|100=|1000=|10 000=|50 000=|100 000=|screenshot=|www=}}').keys
params_o = Infobox.parse('{{Wikiprojekt infobox|wikiprojekt=|logo=|data uruchomienia=|artykułów=|użytkowników=|administratorów=|100=|1000=|10 000=|50 000=|100 000=|200 000=|500 000=|1 000 000=|1 500 000=|2 000 000=|2 500 000=|3 000 000=|screenshot=|www=}}').keys

l = s.make_list 'whatembeds', "Szablon:#{t}"
l -= ['Szablon:Wikiprojekt infobox', 'Szablon:Wikiprojekt infobox/opis']

l.each do |a|
	puts a
	
	p = Page.new a
	ib_orig = Infobox.extract_ib_from_text p.text, t.sub(' infobox', '')
	ib = Infobox.parse ib_orig
	
	ib.rename 'ilość_artykułów', 'artykułów'
	ib.rename 'data_uruchomienia', 'data uruchomienia'
	ib.rename 'adres', 'www'
	ib['www'] = 
		(ib['www'].start_with?('http') ? '' : 'http://') +
		ib['www'] +
		(ib['www'].end_with?('/') ? '' : '/')
	;
	
	['200 000', '500 000', '1 000 000', '1 500 000', '2 000 000', '2 500 000', '3 000 000'].each do |k|
		ib.delete k if ib[k].to_s.strip.empty?
	end
	
	ib.keys.each do |k|
		ib.delete k and puts "--> #{k}" unless params_o.include? k
	end
	
	ib.name = 'Projekt Fundacji Wikimedia'
	
	p.text.sub! ib_orig, ib.pretty_format(param_order: params_o, reqd_params: params_r)
	
	# czasem jest tu kilka...
	ib_orig = Infobox.extract_ib_from_text p.text, 'Strona WWW'
	ib = Infobox.parse ib_orig if ib_orig
	p.text.sub! ib_orig, ib.pretty_format if ib_orig
	
	p.code_cleanup
	
	p.save
end
