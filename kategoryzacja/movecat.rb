# coding: utf-8

# raise "kodowanie ARGV zepsute, do zbadania"



require 'sunflower'
s = Sunflower.new.login

from = 'Kategoria:Linie lotnicze według krajów'
to   = 'Kategoria:Linie lotnicze według ‎państw'
reason = 'ujednolicanie'

# puts "too few arguments!" and exit if ARGV.length<2
# from = ARGV[0].strip.encode('utf-8')
# to   = ARGV[1].strip.encode('utf-8')
# reason = ARGV[2] && ARGV[2].strip.encode('utf-8')

# p ARGV[0]
# p ARGV[0].encoding
# p from, to
# exit

from = 'Kategoria:'+from unless from.start_with? 'Kategoria:'
to = 'Kategoria:'+to unless to.start_with? 'Kategoria:'
reason = nil if reason and reason.strip==''


s.summary = "zmiana nazwy kategorii: [[:#{from}]] → [[:#{to}]]#{reason && " (#{reason})"}"

# 1. move the category itself
# f = Page.new from
# t = Page.new to

# t.text = f.text
# t.save

# f.prepend "{{ek|#{s.summary}}}"
# f.save

# 2. move the articles
list = s.make_list 'category', from
list.pages_preloaded.each do |p|
	p.change_category from, to
	p.save
end

