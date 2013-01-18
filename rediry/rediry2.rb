require 'sunflower'
require 'parallel_each'

s = Sunflower.new.login

list = Marshal.load File.binread 'lista-marshal'

f = File.open('redirywynik.txt', 'w')
f.sync = true

done = 0
Thread.new{loop{puts done; sleep 20}}

list.p_each(5) do |title, text|
# list.each_with_index do |(title, text), i|
	begin
		p = Page.new
		p.text = text
		p.code_cleanup
		text = p.text
		
		text =~ /\[\[([^\|#\]]+)#([^\|\]]+)/
		target, anchor = $1.strip, $2.strip
		
		res = s.API(action:'parse', prop:'sections', page: target)
		sections = res['parse']['sections'].map{|hsh| CGI.unescape hsh['anchor'].gsub(/\.([0-9A-F])/, '%\1').gsub('_',' ') }
		
		f.print "# {{noredirect|#{title.include?('=') ? '1=' : ''}#{title}}} kieruje do [[#{target}##{anchor}]]\n" if !(sections.include? anchor)
		done+=1
		# puts i if i%100==0
	rescue # throws up is redirect is malformed or target contains HTML entities - these should be fixed by hand anyway
		puts $!
		puts title
	end
end

f.close