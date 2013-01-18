# coding: utf-8

require 'sunflower'
require 'memoize'

class Sunflower; include Memoize; end
s = Sunflower.new.login
s.memoize :make_list, 'tmp-memo'

opisy = s.make_list 'category', 'Kategoria:Opisy_szablonów'
infoboksy = (
	(s.make_list 'category-r', 'Kategoria:Infoboksy') - 
	(s.make_list 'category', 'Kategoria:Szablony infoboksów') -
	(s.make_list 'category-r', 'Kategoria:Stacja kolejowa infobox z błędem')
).map{|a| a+'/opis'}


s.summary = '+info o roli szablonu'


todo = opisy & infoboksy

slowly = true
todo.each_with_index do |name, i|
	p = Page.new name
	
	# literówka
	p.text = p.text.sub(
		%Q{* '''Przed wstawieniem szablonu zapoznaj się z [[Pomoc:Infoboks|informacją roli szablonu]] w artykule.'''}, 
		''
	)
	p.text = p.text.sub(
		%Q{* '''Przed użyciem szablonu zapoznaj się z [[Pomoc:Infoboks|informacją roli szablonu]] w artykule.'''}, 
		''
	)
	
	# nie ma naglowka?
	unless p.text.index(/(==+)\s*(U[żz]ycie|Zastosowanie|Wywo[łl]anie|Instrukcja|Sposób użycia)( szablonu)?\s*\1/i)
		p.text = p.text.sub(
			%Q{<!-- DODAWAJ KATEGORIE I INTERWIKI NA DOLE STRONY -->}, 
			%Q{<!-- DODAWAJ KATEGORIE I INTERWIKI NA DOLE STRONY -->\n\n== Użycie ==}
		)
	end
	
	
	# dodaj notkę
	p.text = p.text.sub(
		/(==+)\s*(U[żz]ycie|Zastosowanie|Wywo[łl]anie|Instrukcja|Sposób użycia)( szablonu)?\s*\1 *(\r?\n)+/i,
		%Q{\\1 Użycie \\1\n* '''Przed wstawieniem szablonu zapoznaj się z [[Pomoc:Infoboks|informacją o roli infoboksu]] w artykule.'''\n\n}
	)
	
	
	if p.text.scan('Pomoc:Infoboks').length == 1
		p.save
		puts "#{(i+1).to_s.rjust 3}/#{todo.length} #{name}"
		
		if slowly
			slowly = !(gets.strip=='ok')
		end
	else
		puts "#{(i+1).to_s.rjust 3}/#{todo.length} #{name} - error!"
	end
end

