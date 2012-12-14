'''
An image file parser that checks for DCPU16 compliance
and returns unique font characters and colors for the color palette
'''

import sys
from PIL import Image

def make_len_2(hex_thing):
    hex_thing = hex_thing[2:]
    return '0x%s%s' % ('0'*(2 - len(hex_thing)), hex_thing)

def make_len_4(hex_thing):
    hex_thing = hex_thing[2:]
    return '0x%s%s' % ('0'*(4 - len(hex_thing)), hex_thing)

def get_palette_entry(col):
    # col is a tuple in (r,g,b) format with colors from 0 to 255
    def format_el(el):
        int_val = int(round(el/255.0*15.0))
        str_val = hex(int_val)
        return str_val[2:]

    col = "0x0"+''.join([format_el(el) for el in col])
    return make_len_4(col)

def read_grid_square(pixels, startx, starty, existing_colors):
    all_words = list()
    local_palette = dict()
    for x in range(startx,startx+4):
        for y in range(starty+7,starty-1,-1):
            new_entry = get_palette_entry(pixels[x,y])
            if not new_entry in local_palette:
                local_palette[new_entry] = len(local_palette)
            if len(local_palette) > 2:
                raise Exception("A character can only use 2 colors!!!")
            if new_entry in existing_colors:
                local_palette[new_entry] = existing_colors[new_entry][0][0]
            all_words.append(local_palette[new_entry])

    all_words = ''.join([str(i) for i in all_words])
    words = (make_len_4(hex(int('0b'+all_words[0:16],2))), 
            make_len_4(hex(int('0b'+all_words[16:32],2))))

    return (words, local_palette.keys())

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
        print '    ;' + ' '.join([nice_format(c) for c in displayChar[y]]) + ';'
        
def generate_animation(anim_title = "walking", frame_size = (3,2), frame_count = 3, offset_idx = 0):
    frame_width, frame_height = frame_size

    curr_index = 0
    
    all_chars = enumerate(unique_chars)
    for x in range(0+18, frame_width+18):
        for y in range(frame_height):
            print ":"+anim_title+"_"+str(curr_index) + " ; ("+str(x)+", "+str(y)+")"
            for frame_i in range(frame_count):
                fg_col = "0"
                bg_col = "0"
                font_char = "00"
                font_char_idx = 0
                fg_col_idx = 0
                bg_col_idx = 0
                curr_x,curr_y = (x+(frame_i*frame_width),y)
                for i,color in enumerate(color_palette):
                    for (col_type,xy) in color_palette[color]:
                        if (xy[0], xy[1]) == (curr_x,curr_y):
                            if col_type == 0:
                                #bg
                                bg_col = hex(i)[2:]
                                bg_col_idx = i
                            else:
                                fg_col = hex(i)[2:]
                                fg_col_idx = i
                for (i, char) in enumerate(unique_chars):
                    for xy in unique_chars[char]:
                        if (xy[0], xy[1]) == (curr_x,curr_y):
                            font_char_idx = i + offset_idx
                            font_char = make_len_2(hex(i + offset_idx))[2:]
                print "    DAT 0x%s%s%s ; %s fg#%d bg#%d C#%d" % (fg_col, bg_col, font_char, (curr_x,curr_y), fg_col_idx, bg_col_idx, font_char_idx)
            curr_index += 1

if __name__ == "__main__":
    offset = int(sys.argv[2])
    im = Image.open(sys.argv[1])

    width,height = im.size

    pix = im.load()

    unique_chars = dict()
    color_palette = dict()
    for x in range(int(width/4)):
        for y in range(int(height/8)):
            words, local_palette = read_grid_square(pix, x*4, y*8, color_palette)
            for (i,color) in enumerate(local_palette):
                if not color in color_palette:
                    color_palette[color] = list()
                color_palette[color].append((i,(x,y)))
            if notted(words) in unique_chars:
                unique_chars[notted(words)].append((x,y))
            else:
                if not words in unique_chars:
                    unique_chars[words] = list()
                unique_chars[words].append((x,y))

    print ":monitorFont"
    for (i, char) in enumerate(unique_chars):
        print "    ; Font Char %s" % (i + offset)
        print "    ; Used..."
        for (x,y) in unique_chars[char]:
            print "        ; at (%s,%s)" % (x,y)
        gen_palette_comment(char)
        print "    DAT %s, %s" % tuple([word for word in char])

    print ":monitorPalette"
    for color in color_palette:
        print "    ; Used..."
        for (col_type,xy) in color_palette[color]:
            if col_type == 0:
                col_type = 'bg'
            else:
                col_type = 'fg'
            print "        ; at (%s,%s) as %s color" % (xy[0], xy[1], col_type)
        print "    DAT %s" % color

    generate_animation("jumping", (3,2), 3)