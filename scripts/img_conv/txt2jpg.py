import PIL,numpy,argparse,os
from PIL import Image

def validate_file(f):
    if not os.path.exists(f):
        # Argparse uses the ArgumentTypeError to give a rejection message like:
        # error: argument input: x does not exist
        raise argparse.ArgumentTypeError("{0} does not exist".format(f))
    return f


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Convert a txt bitmap image to jpeg.")
    parser.add_argument("-i", "--input", dest="filename", required=True, type=validate_file,
                        help="input file", metavar="FILE")
    args = parser.parse_args()
    inp_path = os.path.abspath(args.filename)
    out_path = os.path.join(os.path.dirname(inp_path),os.path.splitext(os.path.basename(inp_path))[0]+".jpg")


    txt_img = open(inp_path,'r')
    y_pixels = int(txt_img.readline().strip())
    x_pixels = int(txt_img.readline().strip())
    
    a = numpy.ndarray(shape=(y_pixels,x_pixels), dtype=numpy.uint8)
    for i in range(0,y_pixels):
        line=txt_img.readline().strip()
        for j in range(0,x_pixels):
            a[i][j]=int(line[2*j:2*j+2],base=16)

    #print(a[0])

    image=Image.fromarray(a)
    #print(type(image))
    #print(image.mode)
    #print(image.size)
    #image.show()
    print("Saving"+out_path)
    image.save(out_path)

