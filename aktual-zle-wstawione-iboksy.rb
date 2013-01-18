# coding: utf-8

require 'sunflower'
s = Sunflower.new.login
s.summary = 'jednorazowa aktualizacja list'

bad = /class *= *"?infobox"?|class *= *"?hiddenStructure|\{\{ *[Ii]nfobox[ _]|\A{\|/
good = /\{\{.+?infobox/

asd = <<EEE
Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/Medalista
Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/jedn adm
Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/olimpiady
Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/Pierwiastek
Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/Odkryte planetoidy
Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/żużel
EEE
# asd = <<EEE
# Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/olimpiady
# EEE

asd.split(/\r?\n/).each do |aaaa|


outp = Page.new aaaa
out = outp.text.split(/\r?\n/)

list = (s.make_list 'linkson', aaaa).reject{|a| a=~/:/}

p list.length


own = s.make_list 'usercontribs', 'MatmaBot';

list.each do |t|
	# text = Page.new(t).text
	
	# if text =~ /\A#/
		# t2 = text.match(/\[\[(.+?)\]\]/)[1]
		# text = Page.new(t2).text
	# end
	
	# if (text =~ good and text !~ bad) or text.strip==''
	if own.include? t
		puts "#{t} done"
		out -= out.grep /\[\[#{Regexp.escape t}/i
	else 
		puts "#{t} bad"
	end
end

outp.text = out.join "\n"
outp.save


end