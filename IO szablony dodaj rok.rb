# coding: utf-8
require 'sunflower'

s = Sunflower.new.login
s.summary = "+Londyn 2012"


tpls = s.make_list 'category', 'Kategoria:Szablony nawigacyjne - igrzyska olimpijskie - państwa'

countries = s.make_list 'linkson', 'Państwa uczestniczące w Letnich Igrzyskach Olimpijskich 2012'

countries = countries.select{|a| a.include? ' na Letnich Igrzyskach Olimpijskich 2012'}.map{|a| a.sub ' na Letnich Igrzyskach Olimpijskich 2012', ''}

tpls = tpls.select{|a| a.start_with? 'Szablon:IO '}.select{|a| countries.include? a.sub('Szablon:IO ', '') }


puts tpls.length
puts countries.length

tpls.each do |t|
	cntr = t.sub('Szablon:IO ', '')

	puts t
	p = Page.new t
	if p.text =~ /2012/
		puts 'skipped'
		next
	else
		if p.text.sub! /(\[\[#{Regexp.escape cntr} na Letnich Igrzyskach Olimpijskich \d+\|.+?\]\])(\s*+)(?!•)/, "\\1 • \n[[#{cntr} na Letnich Igrzyskach Olimpijskich 2012|Londyn&nbsp;2012]]\\2"
			p.save
			puts 'changed'
		else
			puts 'no change?'
		end
	end
	
	$ok = gets.strip=='ok' unless $ok
end





