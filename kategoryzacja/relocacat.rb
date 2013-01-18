# coding: utf-8
require 'sunflower'
s = Sunflower.new.login

from = 'Half-Life 2'
to   = 'Half-Life'
reason = "decyzja z [[Wikipedia:Poczekalnia/kwestie techniczne/2012:08:09:Kategoria:Half-Life 2|poczekalni]]"

from = 'Kategoria:'+from unless from.start_with? 'Kategoria:'
to = 'Kategoria:'+to unless to.start_with? 'Kategoria:'
reason = nil if reason and reason.strip==''


s.summary = "połączenie kategorii: [[:#{from}]] → [[:#{to}]]#{reason && " (#{reason})"}"

# 1. move the category itself
f = Sunflower::Page.new from, s

f.prepend "{{ek|#{s.summary}}}"
f.save

# 2. move the articles
list = s.make_list 'category', from
list.pages_preloaded.each do |p|
	p.change_category from, to
	p.save
end

