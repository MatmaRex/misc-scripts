# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

aa = <<EOF
Category and title name
Category name~~~Title name
EOF

class Sunflower::Page
	def add_category cat
		cat_regex = self.sunflower.ns_regex_for 'Category'
		cat = cat.sub(/^#{cat_regex}:/, '')
		
		self.text.sub!(/\[\[ *#{cat_regex} *:|\z/, "[[Kategoria:#{cat}]]\n\\&")
		true
	end
end

kwgzm = 'Kategoria:Kategorie według zespołów muzycznych'

aa.strip.split(/\r?\n/).each do |q|
	cat, title = q.split '~~~'
	title ||= cat
	cat = 'Kategoria:'+cat
	
	cat_cat = s.make_list 'categories_on', cat
	title_cat = s.make_list 'categories_on', title
	
	cat = s.page cat
	title = s.page title
	
	cat.remove_category kwgzm
	cat_cat -= [kwgzm]
	
	cat_cat.each do |c|
		cat.remove_category c
		title.add_category c unless title_cat.include? c
	end
	
	cat.add_category kwgzm
	s.summary = 'przeniesienie do drzewa kategorii tematycznych'
	cat.save
	
	title.add_category cat.title+'| ' unless title_cat.include? cat.title
	s.summary = "synchronizacja kategorii z [[#{cat.title}]]"
	title.save
	
	puts q
	# gets
end
