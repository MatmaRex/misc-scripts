# coding: utf-8
require 'sunflower'
s = Sunflower.new.login

print "."
linkiusa = s.make_list 'whatembeds', 'Szablon:Linki do map Stanów Zjednoczonych'
print "."
linkipor = s.make_list 'whatembeds', 'Szablon:Linki do map Portugalii'
print "."
koord = s.make_list 'whatembeds', 'Szablon:Koordynaty'
print "."
portlok = s.make_list 'whatembeds', 'Szablon:Mapa lokalizacyjna/PRT'
puts ""

puts <<EOF
USA: #{linkiusa.length}, bez koord. #{(linkiusa-koord).length}
POR: #{linkipor.length}, bez koord. #{(linkipor-portlok).length}
EOF

s.summary = "usunięcie {{Linki do map Portugalii}}, [[Wikipedia:Poczekalnia/kwestie techniczne/2012:05:26:Szablon:Linki do map Portugalii|decyzja z poczekalni]]"
(s.make_list 'pages', (linkipor&portlok)).pages_preloaded.each do |p|
	p.text.gsub! /\{\{(szablon:|template:|)Linki do map Portugalii[^{}]+\}\} *\r?\n/i, ''
	p.text.gsub! /\=+ *Linki +zew\S* *=+\n\n/, ''
	p.save
end

s.summary = "usunięcie {{Linki do map Stanów Zjednoczonych}}, [[Wikipedia:Poczekalnia/kwestie techniczne/2012:05:26:Szablon:Linki do map Stanów Zjednoczonych|decyzja z poczekalni]]"
(s.make_list 'pages', (linkiusa&koord)).pages_preloaded.each do |p|
	p.text.gsub! /\{\{(szablon:|template:|)Linki do map Stanów Zjednoczonych[^{}]+\}\} *\r?\n/i, ''
	p.text.gsub! /\=+ *Linki +zew\S* *=+\n\n/, ''
	p.save
end

s.summary = "zamiana {{Linki do map Stanów Zjednoczonych}} na {{[[szablon:koordynaty|koordynaty]]}}, [[Wikipedia:Poczekalnia/kwestie techniczne/2012:05:26:Szablon:Linki do map Stanów Zjednoczonych|decyzja z poczekalni]]"
(s.make_list 'pages', (linkiusa-koord)).pages_preloaded.each do |p|
	data = nil
	p.text.gsub!(/\{\{(szablon:|template:|)Linki do map Stanów Zjednoczonych[^{}]+\}\} *\r?\n/i){data=$&.strip; ""}
	p.text.gsub! /\=+ *Linki +zew\S* *=+\n\n/, ''
	
	data = data.sub /(szablon:|template:|)Linki do map Stanów Zjednoczonych/i, "koordynaty"
	p.text.sub! /\[\[(kategoria|category):/i do data+"\n\n"+$& end or raise
	
	p.save
end
