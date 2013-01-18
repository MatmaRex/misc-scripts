# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

tpl = 'Spis treści obok infoboksu'
pocz = 'Wikipedia:Poczekalnia/kwestie techniczne/2012:01:08:Szablon:Spis treści obok infoboksu'


s.summary = "-{{#{tpl}}} - [[#{pocz}|usunięty po dyskusji w Poczekalni]]"
list = s.make_list 'whatembeds', 'Szablon:'+tpl

list.pages_preloaded.each do |p|
	p.replace(/(\r?\n)?\{\{([sS]zablon:|[tT]emplate:|)#{tpl}\}\}/i, "")
	p.save
	puts p.title
end
