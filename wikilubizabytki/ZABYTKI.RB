# coding: utf-8

require 'spreadsheet'
Spreadsheet.client_encoding = 'UTF-8'


# format XLSów:
# Województwo, Powiat, Gmina, Miejscowość, Określenie obiektu, Określenie zespołu, Liczba obiektów, Materiał, Datowanie obiektu, Aktualny numer rejestru, Ulica


# wynik[woj][powiat][gmina] = ...
wynik = {}

begin
	wynik = Marshal.load File.binread 'zabytki-mar'
rescue
	Dir['*.xls'].sort.each do |sheetname|
		puts sheetname
		sheet = Spreadsheet.open(sheetname).worksheet 0
		
		sheet.each(1) do |row| # skip first
			woj, powiat, gmina, miejscowosc, obiekt, zespol, liczba, material, datowanie, numer_rej, ulica = *row.to_a
			
			# sanitize
			liczba = liczba.to_i.to_s
			datowanie = (datowanie.is_a?(Float) ? datowanie.to_i.to_s : datowanie.to_s)
			woj, powiat, gmina, miejscowosc, obiekt, zespol, material, numer_rej, ulica = *[woj, powiat, gmina, miejscowosc, obiekt, zespol, material, numer_rej, ulica].map(&:to_s).map(&:strip)
			
			numer = numer_rej
			nazwa = (obiekt + ' ' + zespol).strip
			adres = "[[#{miejscowosc}]]" + (ulica!='' ? ', '+ulica : '')
			
			gmina = gmina.sub(/- *(?:gm|m)\.\Z/i, '').strip # utnij dziwne dopiski
			
			miasto_powiat = /\Am\.|- *p\. *m\.\Z/i # miasto na praw. powiatu - jako "m. Xxx" lub "Xxx - p.m."
			if powiat =~ miasto_powiat
				if powiat == 'm. st. Warszawa'
					powiat = 'Warszawa'
					gmina = gmina # dzielnice
				else
					powiat = powiat.gsub(miasto_powiat, '').strip
					gmina = ''
				end
			end
			
			wynik[woj] ||= {}
			wynik[woj][powiat] ||= {}
			wynik[woj][powiat][gmina] ||= []
			
			wynik[woj][powiat][gmina] << [numer, nazwa, adres]
		end
	end
	
	File.open('zabytki-mar', 'wb'){|f| f.write Marshal.dump wynik}
end

require 'sunflower'
s = Sunflower.new.login
s.summary = 'automatyczna generacja list na podstawie surowych danych (na prośbę [[user:odder|oddera]]) '

# TODO: nie powtarzać kodu
# wygeneruj indeks stron
indeks = []
wynik.each do |woj, powiaty|
	indeks << "=== #{woj} ==="
	
	_indeks = []
	
	powiaty.each do |powiat, gminy|
		gminy.each do |gmina, obiekty|
			if powiat=='Warszawa' # gmina == dzielnica
				pagename = "województwo #{woj}/#{powiat}/#{gmina}/NID"
			elsif gmina=='' # inne miasta na praw. powiatu nie mają gmin
				pagename = "województwo #{woj}/#{powiat}/NID"
			else # zwykłe powiaty
				pagename = "województwo #{woj}/powiat #{powiat}/Gmina #{gmina}/NID"
			end
			
			_indeks << "* [[Wikiprojekt:Wiki Lubi Zabytki/wykazy/#{pagename}|#{pagename}]] ([[Wikiprojekt:Wiki Lubi Zabytki/wykazy/#{pagename.sub '/NID', ''}|link bez /NID]])"
		end
	end
	
	indeks += _indeks.sort
end
p = Page.new 'Wikiprojekt:Wiki Lubi Zabytki/wykazy/indeks'
p.text = indeks.join "\n"
p.save



slowly = true

wynik.each do |woj, powiaty|
	powiaty.each do |powiat, gminy|
		gminy.each do |gmina, obiekty|
			# if powiat=='Warszawa' # gmina == dzielnica
				# filename = "#{woj}-#{powiat}-#{gmina}-NID.txt"
			# elsif gmina=='' # inne miasta na praw. powiatu nie mają gmin
				# filename = "#{woj}-#{powiat}-NID.txt"
			# else # zwykłe powiaty
				# filename = "#{woj}-#{powiat}-Gmina #{gmina}-NID.txt"
			# end
			if powiat=='Warszawa' # gmina == dzielnica
				pagename = "województwo #{woj}/#{powiat}/#{gmina}/NID"
			elsif gmina=='' # inne miasta na praw. powiatu nie mają gmin
				pagename = "województwo #{woj}/#{powiat}/NID"
			else # zwykłe powiaty
				pagename = "województwo #{woj}/powiat #{powiat}/Gmina #{gmina}/NID"
			end
			
			# f = File.open 'test2/'+filename, 'w'
			# f.puts "{{Lista zabytków góra}}"
			p = Page.new 'Wikiprojekt:Wiki Lubi Zabytki/wykazy/'+pagename
			p.text = "{{Lista zabytków góra}}" + "\n"
			
			gminalink = if powiat=='Warszawa' # gmina == dzielnica
				gmina
			elsif gmina=='' # inne miasta na praw. powiatu nie mają gmin
				"[[#{powiat}]]"
			else # zwykłe powiaty
				"[[Gmina #{gmina}|#{gmina}]]"
			end
			
			# sortuj: najpierw wg tego, czy ma podaną ulicę (z ulicą najpierw), potem wg nazwy miejscowosci i ulicy
			obiekty = obiekty.sort_by{|numer, nazwa, adres| [ (adres.include?(',') ? 0 : 1), adres ]}
			
			obiekty.each do |numer, nazwa, adres|
				row = "
				{{Zabytki wiersz
				| numer      = #{numer}
				| nazwa      = #{nazwa}
				| adres      = #{adres}
				| gmina      = #{gminalink}
				| zdjęcie    =
				| koordynaty = 
				}}
				".strip.gsub '				', ''
				
				# f.puts row
				p.text += row + "\n"
			end
			
			# f.puts '|}'
			# f.close
			p.text += '|}' + "\n"
			p.save
			
			slowly = !(gets.strip == 'ok') if slowly
		end
	end
end

