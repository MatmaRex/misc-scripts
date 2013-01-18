# coding: utf-8
require 'sunflower'

s = Sunflower.new.login

linki = s.make_list 'whatlinkshere', 'Sąd Najwyższy (w Polsce)'

do_zrobienia = linki.select{|a| !a.include? ':'}.sort # only main namespace
puts "#{do_zrobienia.length} to do..."

from = 'Sąd Najwyższy (w Polsce)'
to = 'Sąd Najwyższy (Polska)'

s.summary = 'poprawa linku do przekierowania o nieprawidłowym tytule'



slowly = true
do_zrobienia.each do |pagename|
	p = Page.new pagename
	p.text = p.text.gsub(/\[\[#{Regexp.escape from}\]\]/, "[[#{to}]]")
	p.text = p.text.gsub(/\[\[#{Regexp.escape from}\|/, "[[#{to}|")

	if p.text != p.orig_text
		p.save
		puts "#{pagename}: saved"
	else
		puts "#{pagename}: no changes"
	end
	
	if slowly
		slowly = !(gets.strip=='ok')
	end
end

