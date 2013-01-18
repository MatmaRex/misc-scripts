# coding: utf-8
File.open('resorted.txt','w'){|f| f.puts File.readlines('redirywynik.txt').sort_by{|a| [a.split('kieruje')[-1].downcase, a] } }
