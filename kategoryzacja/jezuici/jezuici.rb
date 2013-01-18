# coding: utf-8
require 'sunflower'
require 'memoize'
require 'differ'

class Sunflower
	include Memoize
end

s = Sunflower.new.login
s.memoize :make_list, 'jezuici-memo'

duchowni = s.make_list 'category-r', 'Kategoria:Polscy duchowni katoliccy'
biskupi = s.make_list 'category-r', 'Kategoria:Polscy biskupi katoliccy'
niebiskupi = duchowni - biskupi

# lista kategorii, ktorych nie chcemy
$wywalamy = ['Kategoria:Polscy duchowni katoliccy', 'Kategoria:Polscy biskupi katoliccy', 'Kategoria:Polscy jezuici', 'Kategoria:Polscy franciszkanie', 'Kategoria:Polscy pallotyni']


jezuici = (s.make_list 'category', 'Kategoria:Polscy jezuici').sort
jezuici_biskupi = jezuici & biskupi
jezuici_niebiskupi = jezuici & niebiskupi
jezuici_biskupi_done = s.make_list 'category', 'Kategoria:Polscy biskupi jezuiccy'
jezuici_niebiskupi_done = s.make_list 'category', 'Kategoria:Polscy prezbiterzy jezuiccy'

franciszkanie = (s.make_list 'category', 'Kategoria:Polscy franciszkanie').sort
franciszkanie_biskupi = franciszkanie & biskupi
franciszkanie_niebiskupi = franciszkanie & niebiskupi
franciszkanie_biskupi_done = s.make_list 'category', 'Kategoria:Polscy biskupi franciszkańscy'
franciszkanie_niebiskupi_done = s.make_list 'category', 'Kategoria:Polscy prezbiterzy franciszkańscy'

pallotyni = (s.make_list 'category', 'Kategoria:Polscy pallotyni').sort
pallotyni_biskupi = pallotyni & biskupi
pallotyni_niebiskupi = pallotyni & niebiskupi
pallotyni_biskupi_done = s.make_list 'category', 'Kategoria:Polscy biskupi pallotyńscy'
pallotyni_niebiskupi_done = s.make_list 'category', 'Kategoria:Polscy prezbiterzy pallotyńscy'


# out = %w[
	# jezuici_biskupi
	# jezuici_niebiskupi
	# franciszkanie_biskupi 
	# franciszkanie_niebiskupi 
	# pallotyni_biskupi
	# pallotyni_niebiskupi
# ].map do |nm|
	# ["=== #{nm} ==="] + eval(nm).reject{|a| a.start_with? 'Kategoria:'}.map{|a| "# [[#{a}]]"}
# end

# File.open('zakonnicy.txt', 'w'){|f| f.puts out}



def process list, adding_category
	list.reject{|a| a.start_with? 'Kategoria:'}.each do |art|
		p = Page.get art
		p.code_cleanup
		
		without_changes = p.text.dup
		defsort = ''
		
		$wywalamy.each{|kat| 
			p.text = p.text.gsub(/(?:\r?\n|)\[\[#{Regexp.escape kat}(\|[^\]]+|)\]\]/){defsort = $1; ''}
		}
		
		p.text = p.text.sub(
			/(\[\[Kategoria:[^\]]+\]\])/, 
			"[[#{adding_category}#{defsort}]]\n\\1"
		) unless p.text.include? "[[#{adding_category}"
		
		p.text = 
			p.text.strip + 
			"\n\n[[#{adding_category}#{defsort}]]" unless p.text.include? "[[#{adding_category}"
		
		unless p.text == without_changes
			if $slowly
				puts defsort
				
				puts Differ.diff_by_line(p.text, without_changes)
				$slowly = !(gets.strip=='ok')
			end
			
			p.code_cleanup
			p.save
			puts "#{p.title} - saved."
		else
			puts "#{p.title} - no changes?"
		end
	end
end

s.summary = 'poprawa kategorii duchownych zakonnych, [[WP:SK]]'

$slowly = true

process jezuici_biskupi+jezuici_biskupi_done, 'Kategoria:Polscy biskupi jezuiccy'
process jezuici_niebiskupi+jezuici_niebiskupi_done, 'Kategoria:Polscy prezbiterzy jezuiccy'

process franciszkanie_biskupi+franciszkanie_biskupi_done, 'Kategoria:Polscy biskupi franciszkańscy'
process franciszkanie_niebiskupi+franciszkanie_niebiskupi_done, 'Kategoria:Polscy prezbiterzy franciszkańscy'

process pallotyni_biskupi+pallotyni_biskupi_done, 'Kategoria:Polscy biskupi pallotyńscy'
process pallotyni_niebiskupi+pallotyni_niebiskupi_done, 'Kategoria:Polscy prezbiterzy pallotyńscy'

