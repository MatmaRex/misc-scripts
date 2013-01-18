# coding: utf-8
require 'differ'
Differ.format = :color

require 'sunflower'
s = Sunflower.new.login
list = File.readlines('lang troche.txt').map(&:strip)

langmap = {
	ang: 'en',
	niem: 'de',
	ros: 'ru',
	hiszp: 'es',
	fran: 'fr',
	port: 'pt',
	:'duń' => 'da',
	dk: 'da',
	kor: 'ko'
}


# nie działa dobrze (langi mają iść na koniec)
list.each do |a|
	p a
	p = Page.new a
	
	# zamień nawiasy na {{lang}}i
	p.text = p.text.gsub(/^[=' ]+Linki zewnętrzne[\s\S]+?(?:^=|\Z)/) do |sekcja|
		sekcja.gsub(/\((en|ang|de|niem|ru|ros|es|hiszp|fr|fran|pt|port|dk|duń|kor)\.?\)/){"{{lang|#{langmap[$1.to_sym]||$1}}}"}
	end
	
	# zamień kolejne langi na jeden
	p.text = p.text.gsub(/(\{\{lang\|[a-z-\|]+\}\}[\t ]*){2,10}/i) do |a|
		"{{lang#{a.gsub(/\{\{lang\|([a-z-\|]+)\}\}\s*/, '|\1')}}}"
	end
	
	puts Differ.diff p.text, p.orig_text
	gets
end

