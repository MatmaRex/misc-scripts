# coding: utf-8
require 'sunflower'
require 'set'

s = Sunflower.new.login
list = s.make_list('linkson', 'Wikiprojekt:Wiki Lubi Zabytki/wykazy/indeks').reject{|a| a=~/NID$/}


woj_transl = {
  "wielkopolskie" => "Greater Poland",
  "kujawsko-pomorskie" => "Kuyavian-Pomeranian",
  "małopolskie" => "Lesser Poland",
  "łódzkie" => "Łódź",
  "dolnośląskie" => "Lower Silesian",
  "lubelskie" => "Lublin",
  "lubuskie" => "Lubusz",
  "mazowieckie" => "Masovian",
  "opolskie" => "Opole",
  "podlaskie" => "Podlaskie",
  "pomorskie" => "Pomeranian",
  "śląskie" => "Silesian",
  "podkarpackie" => "Subcarpathian",
  "świętokrzyskie" => "Świętokrzyskie",
  "warmińsko-mazurskie" => "Warmian-Masurian",
  "zachodniopomorskie" => "West Pomeranian"
}


class String
	def ucfirst
		self[0].upcase + self[1..-1]
	end
end


repeated_pow = Hash.new{|h,k| h[k]=Set.new}
repeated_gmi = Hash.new{|h,k| h[k]=Set.new}


list.each do |a|
	begin
		woj, powiat, gmina = 
			a.match(%r|\AWikiprojekt:Wiki Lubi Zabytki/wykazy/województwo ([^/]+)/powiat ([^/]+)/Gmina ([^/]+)\Z|)[1..3]
	rescue
		next # if link doesn't match the regex - miasta na p.pow.
	end
	
	woj = woj_transl[woj]
	
	repeated_pow[powiat] << woj
	repeated_gmi[gmina] << powiat
end


s = Sunflower.new('commons.wikimedia.org').login
s.summary = 'new category'


list.shuffle[0..30].each do |a|
# list.each do |a|
	begin
		woj, powiat, gmina = 
			a.match(%r|\AWikiprojekt:Wiki Lubi Zabytki/wykazy/województwo ([^/]+)/powiat ([^/]+)/Gmina ([^/]+)\Z|)[1..3]
	rescue
		next # if link doesn't match the regex - miasta na p.pow.
	end
	
	gmina_plain = gmina
	
	skip = !(repeated_gmi[gmina].length==1)
	
	woj = "#{woj_transl[woj]} Voivodeship"
	powiat = repeated_pow[powiat].length==1 ? "powiat #{powiat}" : "powiat #{powiat}, #{woj}"
	gmina = repeated_gmi[gmina].length==1 ? "gmina #{gmina}" : "gmina #{gmina}, #{powiat}"
	
	gmina_msc = gmina.sub(/^gmina/, 'gminie')
	
	
	p = Page.new "Category:Cultural heritage monuments in #{gmina}", 'commons.wikimedia.org'
	p.text = "
	{{en|Cultural heritage monuments in {{w|#{gmina}}}.}}
	{{pl|Zabytki nieruchome w {{w|#{gmina}|#{gmina_msc}|pl}}.}}

	{{DEFAULTSORT:#{gmina_plain}}}
	[[Category:Cultural heritage monuments in #{powiat}]]
	[[Category:#{gmina.ucfirst}]]
	".gsub('	','').strip
	
	# jeśli trzeba ujednoznacznić: gmina (powiat) - na pl:, en: i commons: są różne schematy
	# i chyba lepiej zrobić te kilka ręcznie
	if true#skip
		p.dump
	else
		p.save
		sleep 10
	end
	
	
	puts p.title if p.pageid
end
