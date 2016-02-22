"""
Image Click XY

Allows a user to extract rectangular regions from an image
"""
import argparse
from os import listdir
from os.path import abspath, isfile, join, splitext
from sys import exit
import matplotlib.pyplot as plt
import imutils as im


parser = argparse.ArgumentParser(description='Image Click XY')
parser.add_argument("impath", type=str, help="path to image file directory")
parser.add_argument("outpath", type=str, help="path to output file directory")
args = parser.parse_args()

# Set impath and outpath
impath = abspath(args.impath)
outpath = abspath(args.outpath)

# Get image file list
imfiles = [f for f in listdir(impath) if (isfile(join(impath, f)) and not f.startswith('.'))]

# Loop through image files
for imfile in imfiles:

    #read image
    image = im.read(join(impath, imfile))

    #begin program
    while True:

        #initialize interactive image
        clickim = im.ImageClicker(image, 4)

        #extract region
        rect = im.fitrect(clickim.coords)
        region = im.rotocrop(image, rect)

        #display region
        plt.imshow(region)
        plt.ion()
        plt.show()

        #prompt user for action
        try:
            flag = raw_input('Enter s (save), r (retry), sr (save and retry), q (quit), or sq (save and quit): ')
        except TypeError:
            print "Invalid command..."
            continue

        #set filename
        fnum = 1
        filename = splitext(imfile)[0]
        fulloutpath = join(outpath, filename + '_tag' + str(fnum) + '.png')

        while isfile(fulloutpath):
            filename = splitext(imfile)[0]
            fulloutpath = join(outpath, filename + '_tag' + str(fnum) + '.png')
            fnum += 1

        #perform user-defined action
        if flag == 's':
            im.write(region, fulloutpath)
            plt.ioff()
            plt.close()
            break
        elif flag == 'r':
            plt.ioff()
            plt.close()
            continue
        elif flag == 'sr':
            im.write(region, fulloutpath)
            plt.ioff()
            plt.close()
            continue
        elif flag == 'q':
            plt.ioff()
            plt.close()
            exit("Quit")
        elif flag == 'sq':
            im.write(region, fulloutpath)
            plt.ioff()
            plt.close()
            exit("Quit")
        else:
            continue





