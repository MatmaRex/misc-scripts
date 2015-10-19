# coding: utf-8
require 'sunflower'

s = Sunflower.new.login
s.summary = 'poprawa zapisu szablonu {{[[szablon:lang|lang]]}}'
list = s.make_list 'plaintext', File.read('ExistsIn2ButNot1.txt', encoding: 'utf-8')

p list.length
list.pages_preloaded.each_with_index do |p, i|
	orig_text = p.text.dup
	p.text.gsub!(/\[([^\[\]\{\}]+?) *({{lang\|[a-z |]+?}})\](?!\])/, '[\1] \2')
	p p.save if orig_text != p.text
	p i if i % 100 == 0
end
