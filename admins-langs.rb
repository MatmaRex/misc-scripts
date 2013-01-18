# coding: utf-8
require 'sunflower'
require 'pp'

s = Sunflower.new.login

admins = s.API('action=query&list=allusers&augroup=sysop&aulimit=max')
admins = admins['query']['allusers'].map{|a| a['name'] }
admins -= ["Beau.bot.admin"]

order = %w[1 p 2 u 3 4]
langs = {}
admins.each do |adm|
	tpls = (s.make_list 'templateson', "User:#{adm}" rescue [])
	re = /^Szablon:User ([a-z-]+-[1234up])( small)?$/
	langboxes = tpls.grep re
	langs[adm] = langboxes.map{|a| a[re, 1] }.sort_by{|l| [-order.index(l[-1]), l] }
	
	pp langs
end

p = Page.new 'Wikipedia:Administratorzy'
langs.each do |adm, langs|
	admin_re = /(\[\[Specjalna:Wkład\/#{Regexp.escape adm}\|sprawdź\]\]\s*\|(\[\[([^\[\]]+)\]\]|\[([^\[\]]+)\]|[^\[\]|]+)*\s*\|).*/
	
	p.text = p.text.sub(admin_re, '\1'+langs.map{|l| "{{user #{l} small}}" }.join(' '))
end

p.dump

