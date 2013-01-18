# coding: utf-8
require 'pp'
require 'sunflower'
s = Sunflower.new.login
s.summary = 'półautomatyczne sprzątanie układów wielokolumnowych'

File.readlines('nobrk.txt').each do |t|
	p = Page.new t.strip

	# powinien złapać wszystkie tabelki zrobione z {{col-begin}}/{{col-end}}, ale bez {{col-break}}
	# $1, $2, $3 - początek/środek/koniec
	re_magic = /(\{\|.*\r?\n\|-.*|\{\{[cC]ol-begin\}\}(?:\s*\{\{[cC]ol-(?:break|\d+)\}\})?)((?:[\s\S]+?(?=\r?\n(?:\|\r?\n|\|\}|\{\{[cC]ol-end\}\})))?(?:\r?\n\|[\s\S]+?(?=\r?\n(?:\|\r?\n|\|\}|\{\{[cC]ol-end\}\})))*?)\s*(\|\}|\{\{[cC]ol-end\}\})/

	st = p.text.count '{|'
	en = p.text.count '|}'

	if false#st == en
		puts 'Wszystko OK?'
	else
		p.text = p.text.gsub(re_magic){
			_, intro, inside, outro = $&, $1, $2, $3
			
			if intro !~ /\{\{col-/ and outro !~ /\{\{col-/
				puts 'to nie sa kolumny, nie ruszamy'
				_
			elsif inside =~ /\|-/ or inside =~ /\{\|/ or inside =~ /\|\}/ or \
			      inside.gsub(/\[\[[^\]]+\]\]/,'').gsub(/\{\{[^\}]+\}\}/,'').gsub(/\{\{[^\}]+\}\}/,'').include?('|') # ukrywamy linki i zagn. szablony
				puts 'zagniezdzone tabele, to sie nie moze dobrze skonczyc'
				_
			else
				fmt = "{{układ wielokolumnowy|liczba=%d|%s\n%s\n}}"
				
				inside.strip!
				
				count = 0
				inside.gsub!(/(\A|\r?\n)(\||\{\{col-(?:break|\d+)\}\})(\Z|\r?\n)/){count +=1; "\n"}
				count +=1 if intro =~ /\{\{col-(?:break|\d+)\}\}/i
				
				if count > 1
					# fmt % [count, (inside.include?('=') ? '1=' : ''), inside.strip]
					fmt % [count, '', inside.strip]
				else
					inside.strip
				end
			end
		}
		
		if p.text != p.orig_text
			p.save
			
			puts "#{t.strip} saved."
			$cont=(gets.strip == 'ok') unless $cont
		end
	end
end
