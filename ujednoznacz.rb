# coding: utf-8
require 'sunflower'

s = Sunflower.new.login

linki = s.make_list 'whatlinkshere', 'Vercors'
szczyty = s.make_list 'category-r', 'Kategoria:Szczyty Francji'

list = linki & szczyty

from = 'Vercors'
to = 'Vercors (masyw górski)'



puts "#{list.length} to do..."


s.summary = "ujednoznacznienie: [[#{from}]] -> [[#{to}]]"

slowly = true

list.each_with_index do |pagename, i|
	p = Page.new pagename
	
	simple = /\[\[#{Regexp.escape from}\]\]/
	extended = /\[\[#{Regexp.escape from}\|([^\]]+)\]\]/
	# cytuj = /(\|\s*autor link\s*=\s*)Józef Szymański(\s*[\|\}])/
	
	p.text = p.text.gsub(simple, "[[#{to}|#{from}]]")
	p.text = p.text.gsub(extended, "[[#{to}|\\1]]")
	# p.text = p.text.gsub(cytuj, '\1Józef Szymański (historyk)\2')
	
	if p.text != p.orig_text
		p.save
		puts "#{i+1} | #{pagename}: saved"
	else
		puts "#{i+1} | #{pagename}: no changes"
	end
	
	if slowly
		slowly = !(gets.strip=='ok')
	end
end