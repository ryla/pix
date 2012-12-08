'''
An image file parser that checks for DCPU16 compliance
and returns unique font characters and colors for the color palette
'''

import sys
from PIL import Image

def make_len_4(hex_thing):
	hex_thing = hex_thing[2:]
	return '0x%s%s' % ('0'*(4 - len(hex_thing)), hex_thing)

def get_palette_entry(col):
	# col is a tuple in (r,g,b) format with colors from 0 to 255
	def format_el(el):
		int_val = int(round(el/255.0*15.0))
		str_val = bin(int_val)
		return str_val[2:]

	col = "0b0000"+''.join([format_el(el) for el in col])
	return make_len_4(hex(int(col,2)))

def read_grid_square(pixels, startx, starty):
	all_words = list()
	local_palette = dict()
	for x in range(startx,startx+4):
		for y in range(starty+7,starty-1,-1):
			new_entry = get_palette_entry(pixels[x,y])
			if not new_entry in local_palette:
				local_palette[new_entry] = len(local_palette)
			if len(local_palette) > 2:
				raise Exception("A character can only use 2 colors!!!")
			all_words.append(local_palette[new_entry])

	all_words = ''.join([str(i) for i in all_words])
	words = (make_len_4(hex(int('0b'+all_words[0:16],2))), 
			make_len_4(hex(int('0b'+all_words[16:32],2))))
	local_palette = tuple([color for color in local_palette])

	return (words, local_palette)

def notted(words):
	word1, word2 = words
	return (hex(0xffff ^ int(word1,16)), hex(0xffff ^ int(word2,16)))

def make_bin_len_16(bin_thing):
	bin_thing = bin_thing[2:]
	return '0b%s%s' % ('0'*(16 - len(bin_thing)), bin_thing)

def gen_palette_comment(char):
	word1 = bin(int(char[0],16))
	word2 = bin(int(char[1],16))
	char = make_bin_len_16(word1)[2:]+make_bin_len_16(word2)[2:]
	char = char
	displayChar = list()
	for y in range(8):
		displayChar.append(['x']*4)
	
	for y in range(7,-1,-1):
		for x in range(4):
			displayChar[y][x] = char[x*8 + 7 - y]

	def nice_format(c):
		if c == '0':
			return ' '
		else:
			return '*'

	for y in range(8):
		print ';' + ' '.join([nice_format(c) for c in displayChar[y]]) + ';'


if __name__ == "__main__":
	im = Image.open(sys.argv[1])

	width,height = im.size

	pix = im.load()

	unique_chars = set()
	color_palette = set()
	for x in range(int(width/4)):
		for y in range(int(height/8)):
			words, local_palette = read_grid_square(pix, x*4,y*8)
			for color in local_palette:
				color_palette.add(color)
			if not notted(words) in unique_chars:
				unique_chars.add(words)

	print ":monitorFont"
	for char in unique_chars:
		gen_palette_comment(char)
		print "DAT %s, %s" % tuple([word for word in char])

	print ":monitorPalette"
	for color in color_palette:
		print "DAT %s" % color