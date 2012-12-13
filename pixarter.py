'''
An image file parser that checks for DCPU16 compliance
and returns unique font characters and colors for the color palette
'''

import sys
from PIL import Image

FG = 0
BG = 1

class Palette:
    def __init__(self, index_to_color_fgbgs):
        self.index_to_color_fgbgs = index_to_color_fgbgs
        self.colors_to_index = dict()
        for idx in self.index_to_color_fgbgs:
            self.colors_to_index[self.index_to_color_fgbgs[idx][0]] = idx

    def get_index_from_color(self, color):
        #print self.colors_to_index
        return self.colors_to_index[color]

    def get_color_from_index(self, index):
        return self.index_to_color_fgbgs[index][0]

    def get_fgbg_from_color(self,color):
        index = self.get_index_from_color(color)
        return self.index_to_color_fgbgs[index][1]

class CharPalette:
    def __init__(self):
        self.unique_words = list()
        self.loc_to_words = dict()
        self.loc_to_color_idx = dict()

        self.unique_loc_to_words = dict()

    def add_word(self, loc, words, fgcolor, bgcolor):
        self.loc_to_words[loc] = words
        self.loc_to_color_idx[loc] = (bgcolor,fgcolor)
        if not words in self.unique_words:
            self.unique_words.append(words)
            self.unique_loc_to_words[words] = loc

class ImageMap:
    def __init__(self, colors, chars):
        self.colors = colors
        self.chars = chars

    def get_chars(self):
        #print self.chars.loc_to_words
        for char in self.chars.unique_words:
            gen_palette_comment(char)

    def create_image(self, name, size):
        #image = image.copy()
        #image_width, image_height = image.size
        image = Image.new('RGBA',size)
        image_width, image_height = size
        

        image_pixels = image.load()
        '''for x in range(int(image_width/4)):
            for y in range(int(image_height/8)):
                image_pixels[x,y] = (255,0,0,255)
        '''

        for x in range(31):
            for y in range(12):
                char = self.chars.loc_to_words[(x,y)]
                l = self.chars.unique_loc_to_words[char]
                write_to_image(char,image_pixels,x*4,y*8)
                #write_to_image(char,image_pixels,l[0]*4,l[1]*8)

        image.save(name)

    def get_splash_screen(self, char_offset=0):

        def make_len_3(hex_thing):
            hex_thing = hex_thing[2:]
            return '0x%s%s' % ('0'*(3 - len(hex_thing)), hex_thing)

        for i,char in enumerate(self.chars.unique_words):
            #gen_palette_comment(char)
            print "DAT %s, %s ; %s = %s" % (char[0], char[1], i+char_offset, hex(i+char_offset))

        print
        print
        print
        for x in range(32):
            for y in range(12):
                char = self.chars.loc_to_words[(x,y)]
                char_idx = hex(self.chars.unique_words.index(char)+char_offset)[2:]

                if len(char_idx) == 1:
                    char_idx = "0"+char_idx

                bg_col, fg_col = self.chars.loc_to_color_idx[(x,y)]

                assembly_loc = x+32*y
                assembly_loc = make_len_3(hex(assembly_loc))[2:]

                #print "MAD"+str(act_y)
                #print hex(act_y)[2:]
                if char != ('0xffff','0xffff'):
                    print "SET [0x8%s], 0x%s%s%s ; %s Loc %s=0x%s; char_idx: %s=0x%s" % (assembly_loc, bg_col, fg_col, char_idx, (x,y), x+32*y, assembly_loc, self.chars.unique_words.index(char)+char_offset, char_idx)

    def get_anim(self, char_offset=0):

        #char_offset = 117
        # Jumping
        frame_width = 3
        frame_height = 2

        frame_count_x = 3
        frame_count_y = 1

        x_offset = 18
        y_offset = 0

        anim_name = "jumpingPixel"

        '''
        # Walking
        frame_width = 3
        frame_height = 2

        frame_count_x = 3
        frame_count_y = 1

        x_offset = 0
        y_offset = 0
        '''


        def make_len_2(hex_thing):
            hex_thing = hex_thing[2:]
            return '0x%s%s' % ('0'*(2 - len(hex_thing)), hex_thing)

        for i,char in enumerate(self.chars.unique_words):
            #gen_palette_comment(char)
            print "DAT %s, %s ; %s = %s" % (char[0], char[1], i+char_offset, hex(i+char_offset))

        curr_anim = 0
        for x in range(frame_width):
            for y in range(frame_height):
                print ":"+anim_name+"_"+str(curr_anim)
                
                for i in range(frame_count_x):
                    bg_col, fg_col = self.chars.loc_to_color_idx[(x,y)]

                    loc = (x_offset+x+i*frame_width,y_offset+y*frame_count_y)
                    char = self.chars.loc_to_words[loc]
                    char_idx = make_len_2(hex(self.chars.unique_words.index(char)+char_offset))[2:]
                    print "    DAT 0x%s%s%s ; %s" % (bg_col, fg_col, char_idx, loc)
                curr_anim += 1

def get_num_from_rgb(col):
    col = col[0:3]
    # col is a tuple in (r,g,b) format with colors from 0 to 255
    def format_el(el):
        int_val = int(round(el/255.0*15.0))
        str_val = hex(int_val)
        return str_val[2:]
    col = ''.join([format_el(el) for el in col])
    return int('0x%s%s' % ('0'*(4 - len(col)), col),16)

def read_grid_square(pixels, startx, starty, color_palette):
    all_words = list()
    local_palette = set()
    startx *= 4
    starty *= 8
    for x in range(startx,startx+4):
        for y in range(starty+7,starty-1,-1):
            curr_col = get_num_from_rgb(pixels[x,y])
            local_palette.add(curr_col)
            if len(local_palette) > 2:
                print [hex(c) for c in local_palette]
                raise Exception("A character can only use 2 colors!!!")
            fgbg = color_palette.get_fgbg_from_color(curr_col)
            all_words.append(fgbg)

    def make_len_4(hex_thing):
        hex_thing = hex_thing[2:]
        return '0x%s%s' % ('0'*(4 - len(hex_thing)), hex_thing)

    all_words = ''.join([str(i) for i in all_words])
    words = (make_len_4(hex(int('0b'+all_words[0:16],2))), 
            make_len_4(hex(int('0b'+all_words[16:32],2))))

    return words, local_palette # 0s are FG

def write_to_image(char,image_pixels,start_x,start_y):

    def make_bin_len_16(bin_thing):
        bin_thing = bin_thing[2:]
        return '0b%s%s' % ('0'*(16 - len(bin_thing)), bin_thing)

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
            return (0,0,0,255)
        else:
            return (255,255,255,255)

    for y in range(8):
        for x,c in enumerate(displayChar[y]):
            image_pixels[x+start_x,y+start_y] = nice_format(c)

def gen_palette_comment(char):

    def make_bin_len_16(bin_thing):
        bin_thing = bin_thing[2:]
        return '0b%s%s' % ('0'*(16 - len(bin_thing)), bin_thing)

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
        print '    ;' + ' '.join([nice_format(c) for c in displayChar[y]]) + ';'

def parse_image(image, offset = 0):
    color_palette = Palette(
        {
            0: (0x0000, BG), # Black
            1: (0x0e33, FG), # Red
            2: (0x0777, FG), # Person gray
            3: (0x0ccc, FG), # Building gray
            4: (0x0fff, FG), # White
        })

    char_palette = CharPalette()

    image_map = ImageMap(color_palette, char_palette)

    image_width, image_height = image.size
    image_pixels = image.load()

    for x in range(int(image_width/4)):
        for y in range(int(image_height/8)):
            char_words, local_palette = read_grid_square(image_pixels, x, y, color_palette)
            cols = [0,0]
            for col in local_palette:
                cols[color_palette.get_fgbg_from_color(col)] = color_palette.get_index_from_color(col)
            char_palette.add_word((x,y), char_words, cols[FG], cols[BG])

    return image_map


if __name__ == "__main__":
    char_offset = 0
    image_name = ""

    if len(sys.argv) > 1:
        image_name = sys.argv[1]
    else:
        raise Exception("You have not specified an image file!")

    if len(sys.argv) > 2:
        char_offset = int(sys.argv[2])

    image = Image.open(image_name)
    image_map = parse_image(image, offset = char_offset)

    #image_map.create_image("moo.png", image.size)
    image_map.get_splash_screen()
    #image_map.get_anim()
        