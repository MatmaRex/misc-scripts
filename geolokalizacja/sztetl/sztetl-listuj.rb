# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

syn = s.make_list 'categoryr', 'Kategoria:Synagogi Polski'
cmen = s.make_list 'categoryr', "Kategoria:Cmentarze \u017cydowskie w Polsce"
links = s.make_list 'linksearch', '*.sztetl.org.pl/pl/'
list = (cmen.sort + syn.sort) & links.sort

# list = File.readlines('list.txt').map(&:strip).sort
p list.length


require './../infobox parser/infobox parser'


ibox_list_f = File.open('ibox.txt', 'w:utf-8')
wielelinkow_list_f = File.open('wielelinkow.txt', 'w:utf-8')

ibox_list_f.sync = wielelinkow_list_f.sync = true


list.each_with_index do |t, i|
	puts i if i%25==0
	p = Page.new t
	
	ibox = Infobox.find_in_text p.text
	if ibox
		unless ibox.name == 'Synagoga' || ibox.name == 'Cmentarz'
			ibox_list_f.puts t
		end
	else
	
	
	sztetle = p.text.scan(%r|https?://(?:www\.)?sztetl.org.pl/pl/[^\s\[\] ]+|)
	if sztetle.length > 1
		wielelinkow_list_f.puts t
		end
	end
end



