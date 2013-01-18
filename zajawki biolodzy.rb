# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

def wyciagnij_daty plain
	msc = %w[kotek stycznia lutego marca kwietnia maja czerwca lipca sierpnia września października listopada grudnia]
	msc2 = %w[kotek styczeń luty marzec kwiecień maj czerwiec lipiec sierpień wrzesień październik listopad grudzień]
	msc3 = %w[kotek I II III IV V VI VII VIII IX X XI XII]
	
	data_regex = /
		(\d{1,2})(?:-ego|-go|\.|) \s+
		(#{(msc+msc2+msc3).join '|'}|\d{1,2}) \s+
		(\d{3,4})
	/x
	
	data_ur_regex = /(?:ur\.?|urodzon[ya])\s*#{data_regex}/
	data_zm_regex = /(?:zm\.?|zmarł[ya]?)\s*#{data_regex}/
	zasieg_regex = /#{data_regex}\s*[-–—]\s*#{data_regex}/
	
	data_sanitize = lambda do |mt|
		_,d,m,y = *mt
		m = msc.index(m) || msc2.index(m) || msc3.index(m) || m.to_i
		d = d.to_i
		y = y.to_i
		if m!=0 and d!=0 and y!=0
			[d,m,y]
		else
			nil
		end
	end
	
	data_ur, data_zm = *(plain.match(zasieg_regex) do |mt|
		a = mt.to_a
		ur, zm = a[1..3], a[4..6]
		[data_sanitize.call([nil]+ur),   data_sanitize.call([nil]+zm)]
	end)
	
	data_ur ||= plain.match data_ur_regex, &data_sanitize
	data_zm ||= plain.match data_zm_regex, &data_sanitize
	
	return [data_ur, data_zm]
end

def mikrozaj zaj
	zaj = zaj.dup

	zaj.gsub!(/<ref[^>]+?\/>/, '') # wywal refy
	zaj.gsub!(/<ref.+?(<\/ref>|\Z)/, '') # wywal refy
	true while zaj.gsub!(/\s*\([^()]+\)/, '') # wywal nawiasy - zacznij od zagnieżdżonych, do skutku
	zaj.gsub!(/\s*\\{\{.+?\}\}/, '') # wywal {{nihongo}} i inne
	zaj.gsub!(/'''(.+?)'''/, '') # wywal początek
	zaj.gsub!(/(\S{3,}\.)\s+.+/, '\1') # wywal wszystko po pierwszym zdaniu - próbuj ogarnąć skróty
	zaj.gsub!(/\A[^\w\[]+/, '') # wywal śmieci na początku
end

if File.exist? 'biolodzy-marshal'
	biolodzy = Marshal.load File.binread 'biolodzy-marshal'
else
	biolodzy = s.make_list 'categoryr', 'Kategoria:Biolodzy'
	biolodzy.select!{|a| !a.include? ':'}
	File.open('biolodzy-marshal', 'wb'){|f| f.write Marshal.dump biolodzy}
end

# hash - klucze to daty + pare specjalnych, wartosci - tablice structów Info
wyniki = Hash.new{|h,k| h[k] = [] }

Info = Struct.new :nazwisko, :ur, :zm, :zajawka, :tekst


stop = false
trap("INT"){stop = true}




msc = %w[kotek stycznia lutego marca kwietnia maja czerwca lipca sierpnia września października listopada grudnia]
biolodzy.each_with_index do |nazwisko, i|
	puts i

	p = Page.new nazwisko
	lines = p.text.split /\r?\n/
	zajawka = lines.grep(/\A(Sir|Dame|ks\.)?\s*('''|{{nihongo\|''')/i)[0]
	
	info = Info.new
	info.nazwisko = nazwisko
	
	if !zajawka
		wyniki[:bezzajawki] << info
		next
	else
		info.zajawka = zajawka
	end
	
	plain = zajawka.gsub(/<ref.+?<\/ref>/, '').gsub(/\[\[([^\|\]]+\||)([^\|\]]+)\]\]/, '\2')
	
	# info.zajawka = plain
	
	data_ur, data_zm = *wyciagnij_daty(plain)
	info.zm, info.ur = data_zm, data_ur
	
	if data_ur or data_zm
		if data_ur
			d,m,y = *data_ur
			
			tmp = info.dup
			mikrozajawka = mikrozaj(zajawka)
			tmp.tekst = "w #{y} urodził(a) się [[#{info.nazwisko}]]#{data_zm && " (zm. #{data_zm[2]})"} – #{mikrozajawka}"
			
			wyniki["#{d} #{msc[m]}"] << tmp
		end
		if data_zm
			d,m,y = *data_zm
			
			tmp = info.dup
			mikrozajawka = mikrozaj(zajawka)
			tmp.tekst = "w #{y} zmarł(a) [[#{info.nazwisko}]]#{data_ur && " (ur. #{data_ur[2]})"} – #{mikrozajawka}"
			
			wyniki["#{d} #{msc[m]}"] << tmp
		end
	else
		wyniki[:bezdaty] << info
	end
	
	break if stop
end

# require 'pp'
# PP.pp wyniki

out = File.open('biolodzy.txt', 'w')

msc = %w[kotek stycznia lutego marca kwietnia maja czerwca lipca sierpnia września października listopada grudnia]

order = 
	[:bezzajawki, :bezdaty] +
	(1..31).map{|a| "#{a} #{msc[1]}"} +
	(1..29).map{|a| "#{a} #{msc[2]}"} +
	(1..31).map{|a| "#{a} #{msc[3]}"} +
	(1..30).map{|a| "#{a} #{msc[4]}"} +
	(1..31).map{|a| "#{a} #{msc[5]}"} +
	(1..30).map{|a| "#{a} #{msc[6]}"} +
	(1..31).map{|a| "#{a} #{msc[7]}"} +
	(1..31).map{|a| "#{a} #{msc[8]}"} +
	(1..30).map{|a| "#{a} #{msc[9]}"} +
	(1..31).map{|a| "#{a} #{msc[10]}"} +
	(1..30).map{|a| "#{a} #{msc[11]}"} +
	(1..31).map{|a| "#{a} #{msc[12]}"}

order.each do |data|
	out.puts "\n=== #{data} ==="
	if wyniki[data] and !wyniki[data].empty?
		wyniki[data].each do |info|
			out.puts "* "+(
				info.tekst or 
				(info.zajawka && ("[[#{info.nazwisko}]] / "+info.zajawka.gsub(/<ref.+?(<\/ref>|\Z)/, '')) ) or 
				"[[#{info.nazwisko}]]"
			)
		end
	else
		out.puts "''brak''"
	end
end

out.close





