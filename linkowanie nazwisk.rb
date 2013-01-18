# coding: utf-8

require 'sunflower'
s = Sunflower.new.login
s.summary = 'próba automatycznego podlinkowania fragm. wyglądających jak nazwiska'

p = Page.new 'Wikipedysta:Sp5uhe/brudnopis'
t = p.text

p.text = t.gsub(/\n\n((?!Nagroda|Honorow|Utw[óo]r|Twórczo)\p{Lu}\p{Ll}+(?: (?!Urodz|Uko|Dyrygent|Kompozyt)\p{Lu}\p{Ll}+)+)/) do
	"\n\n[[#{$1}]]"
end

puts p.text

p.save
