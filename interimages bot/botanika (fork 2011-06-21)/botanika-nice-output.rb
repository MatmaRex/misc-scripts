# coding: utf-8
# by Matma Rex
# matma.rex@gmail.com
# released under CC-BY-SA 3.0

results = Marshal.load File.open('results-marshal','rb'){|f| f.read}

# Calls bysize, then uploads all full files (ie. all except last) to the Wiki.
def do_update! results
	require 'sunflower'
	s = Sunflower.new.login
	
	basepage = "Wikiprojekt:Botanika/Ilustrowanie"
	s.summary = 'automatyczny update listy'
	
	files = bysize results
	files.pop
	
	files.each do |fn|
		titlebit = fn.sub(/\.txt\Z/, '')
	
		text = File.read fn
		p = Page.new "#{basepage}/#{titlebit}"
		
		if !p.pageid # page doesn't exist yet
			p.text = "Zobacz: [[#{basepage}]]." + "\n\n" + text
			p.save
		
			puts "#{titlebit} - saved."
		else
			puts "#{titlebit} - already there."
		end
	end
	
	p = Page.new "#{basepage}/ignored"
	p.text = File.read "ignored.txt"
	p.save
	
	puts 'ignored'
end

# Output all results to a single file. Returns an array containing its filename.
def quickout results
	out = File.open('out.txt','w')
	out.sync=true
	
	results.each_pair do |k,v|
		name, images, interwikimap = k, *v
		
		out.puts "* [[#{name}]]"
		out.puts images.to_a.map{|img, langs| 
			"** [[:commons:File:#{img}|]] na #{langs.uniq.map{|l| "[[:#{l}:#{interwikimap[l.to_s]}|#{l}]]"}.join ','}"
		}
	end
	
	out.close
	
	return ['out.txt']
end

# Output results to multiple files, num (default: 1000) articles in each. Returns an array containing filenames of created files.
def bynum results, num=1000
	files = []
	
	results.to_a.each_slice(num).with_index do |res, i|
		nums = "#{num*i+1}-#{num*i+res.length}"
		
		fname = "out-#{nums}.txt"
		files << fname
		
		out = File.open(fname,'w')
		
		res.each do |k,v|
			name, images, interwikimap = k, *v
			
			out.puts "* [[#{name}]]" unless images.empty?
			out.puts images.to_a.map{|img, langs| 
				"** [[:commons:File:#{img}|]] na #{langs.uniq.map{|l| "[[:#{l}:#{interwikimap[l.to_s]}|#{l}]]"}.join ','}"
			}
		end
		
		out.close
		
		puts nums
	end
	
	return files
end

# Output results to multiple files, as close to maxsize bytes in each (default: 100 Kbytes). Returns an array containing filenames of created files.
def bysize results, maxsize=100*1024
	files = []
	
	next_file=1
	frgm=[]
	len=0
	
	results.each_pair do |k,v|
		name, images, interwikimap = k, *v
		
		unless images.empty?
			frgm << "* [[#{name}]]"
			len += frgm.last.length
			images.to_a.each{|img, langs| 
				frgm << "** [[:commons:File:#{img}|]] na #{langs.uniq.map{|l| "[[:#{l}:#{interwikimap[l.to_s]}|#{l}]]"}.join ','}"
				len += frgm.last.length
			}
		end
		
		if len >= maxsize
			fname = "#{next_file}.txt"
			files << fname
			
			File.open(fname,'w'){|f| f.puts frgm}
			puts next_file
			
			frgm=[]
			len=0
			next_file+=1
		end
	end
	
	unless frgm.empty?
		fname = "#{next_file}.txt"
		files << fname
		
		File.open(fname,'w'){|f| f.puts frgm}
		puts next_file
	end
	
	return files
end


count = Hash.new{0}
results.each_pair do |k,v|
	name, images, interwikimap = k, *v
	images.each_pair do |img, langs|
		count[img]+=1
	end
end


max = count.to_a.select{|a| a[1] >= 10} # select files used 10 times or more
max = max.sort_by{|a| a[1]}.reverse # sort them by usage

exclude = max.map{|a| a[0]} # just the filenames


results.each_pair do |k,v|
	name, images, interwikimap = k, *v
	images.delete_if{|k,v| exclude.include? k}
end

File.open('ignored.txt','w'){|f| f.puts max.map{|img, uses| "* [[:commons:File:#{img}|]] - #{uses}"}}

case ARGV[0]
when '--plain'
	quickout results
when '--bynum'
	bynum results
when '--bysize'
	bysize results
when '--do-update'
	do_update! results
else
	puts %w[--plain --bynum --bysize --do-update]
end

