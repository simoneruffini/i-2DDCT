# PNG to PPM convertion 

1) Make sure to install [NetPbm utils](http://netpbm.sourceforge.net/)
3) Make sure to install [ImageMagick](https://imagemagick.org/)

## Convert PNG to PPM P3 (Ascii)
Run

```sh
pngtopnn input_file.png | convert - -compress none result.ppm
```

# Convert PNG to PPM P6 (binary)
Run

```sh
pngtopnn input_file.png > result.ppm
```
