# coding: utf-8

require 'json'
require 'execjs'
require 'base64'
require 'rest-client'


# JavaScript doesn't have native Base64 functions; we need to roll out our own.
BASE64JS = <<'EOF'
/**
*
*  Base64 encode / decode
*  http://www.webtoolkit.info/
*  http://www.webtoolkit.info/javascript-base64.html
*  Licensed under CC-BY 2.0
*
**/

var Base64 = {
 
	// private property
	_keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
 
	// public method for encoding
	encode : function (input) {
		var output = "";
		var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
		var i = 0;
 
		input = Base64._utf8_encode(input);
 
		while (i < input.length) {
 
			chr1 = input.charCodeAt(i++);
			chr2 = input.charCodeAt(i++);
			chr3 = input.charCodeAt(i++);
 
			enc1 = chr1 >> 2;
			enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
			enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
			enc4 = chr3 & 63;
 
			if (isNaN(chr2)) {
				enc3 = enc4 = 64;
			} else if (isNaN(chr3)) {
				enc4 = 64;
			}
 
			output = output +
			this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
			this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);
 
		}
 
		return output;
	},
 
	// public method for decoding
	decode : function (input) {
		var output = "";
		var chr1, chr2, chr3;
		var enc1, enc2, enc3, enc4;
		var i = 0;
 
		input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
 
		while (i < input.length) {
 
			enc1 = this._keyStr.indexOf(input.charAt(i++));
			enc2 = this._keyStr.indexOf(input.charAt(i++));
			enc3 = this._keyStr.indexOf(input.charAt(i++));
			enc4 = this._keyStr.indexOf(input.charAt(i++));
 
			chr1 = (enc1 << 2) | (enc2 >> 4);
			chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
			chr3 = ((enc3 & 3) << 6) | enc4;
 
			output = output + String.fromCharCode(chr1);
 
			if (enc3 != 64) {
				output = output + String.fromCharCode(chr2);
			}
			if (enc4 != 64) {
				output = output + String.fromCharCode(chr3);
			}
 
		}
 
		output = Base64._utf8_decode(output);
 
		return output;
 
	},
 
	// private method for UTF-8 encoding
	_utf8_encode : function (string) {
		string = string.replace(/\r\n/g,"\n");
		var utftext = "";
 
		for (var n = 0; n < string.length; n++) {
 
			var c = string.charCodeAt(n);
 
			if (c < 128) {
				utftext += String.fromCharCode(c);
			}
			else if((c > 127) && (c < 2048)) {
				utftext += String.fromCharCode((c >> 6) | 192);
				utftext += String.fromCharCode((c & 63) | 128);
			}
			else {
				utftext += String.fromCharCode((c >> 12) | 224);
				utftext += String.fromCharCode(((c >> 6) & 63) | 128);
				utftext += String.fromCharCode((c & 63) | 128);
			}
 
		}
 
		return utftext;
	},
 
	// private method for UTF-8 decoding
	_utf8_decode : function (utftext) {
		var string = "";
		var i = 0;
		var c = c1 = c2 = 0;
 
		while ( i < utftext.length ) {
 
			c = utftext.charCodeAt(i);
 
			if (c < 128) {
				string += String.fromCharCode(c);
				i++;
			}
			else if((c > 191) && (c < 224)) {
				c2 = utftext.charCodeAt(i+1);
				string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
				i += 2;
			}
			else {
				c2 = utftext.charCodeAt(i+1);
				c3 = utftext.charCodeAt(i+2);
				string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
				i += 3;
			}
 
		}
 
		return string;
	}
 
}
EOF


#
# The code below is in public domain; you can use it freely everywhere.
#

wpsk = RestClient.get 'http://pl.wikipedia.org/w/index.php?title=MediaWiki:Gadget-sk.js&action=raw&ctype=text/javascript'
wpsk = wpsk.force_encoding('utf-8')

# Windows' JScript doesn't support literals such as {a:1, b:2,}
wpsk.sub!(/,\n}/, "\n}")
# these only have meaning when we're in a browser
wpsk.gsub!(/importScript.+/, '')
wpsk.gsub!(/mw\.loader\.load.+/, '')
wpsk.sub!('if (window.wp_sk)', 'if(false)')
wpsk.sub!('window.wp_sk = new Object();', 'var wp_sk = {};')
wpsk.sub!('window.wp_sk_show_as_button = true;', '')
wpsk.sub!('window.wp_sk_redir_enabled = false;', '')
wpsk.sub!(/wp_sk\.redir\.linkPrefix =.+/, 'wp_sk.redir.linkPrefix = "whatevs";')
wpsk.gsub!(/mw\.config\.get *\([^,\)]+,([^\)]+)\)/, '\1') # use defaults
# as well as this
wpsk.sub!(/\/\* *===+\s*OnLoad\s*===+ *\*\/[\s\S]*\Z/, '')

WPSKJS = wpsk

File.write 'asd.txt', WPSKJS

# Perform code cleanup. Returns cleaned up text.
def full_wp_sk text, vars
	vars_js = vars.map{|var, v| "var #{var} = #{v.to_json};" }.join("\n")
	
	ctx = ExecJS.compile(WPSKJS + "\n\n" + BASE64JS + "\n\n" + vars_js)
	
	# we all love encodings
	# base64 prevents crazy artifacts
	new = Base64.decode64(ctx.eval("Base64.encode(wp_sk.cleaner(Base64.decode(#{Base64.encode64(text.force_encoding 'binary').to_json})))")).force_encoding('utf-8')
	
	return new
end

