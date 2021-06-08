package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"strconv"
	"strings"
)

func main() {
	args := os.Args

	var input_ppm_path, output_hex_path, input_ppm_name string

	switch len(args) {
	case 2:
		input_ppm_path = args[1]
		input_ppm_dir := path.Dir(input_ppm_path)
		input_ppm_name = strings.ReplaceAll(path.Base(input_ppm_path), path.Ext(input_ppm_path), "")
		output_hex_path = input_ppm_dir + "/" + input_ppm_name + ".hex"
	case 3:
		input_ppm_path = args[1]
		input_ppm_name = strings.ReplaceAll(path.Base(input_ppm_path), path.Ext(input_ppm_path), "")
		output_hex_path = args[2]
	default:
		fmt.Println("Wrong parameters at least one is expected")
		os.Exit(1)
	}
	fmt.Println(input_ppm_path, output_hex_path)

	infile, err := os.Open(input_ppm_path)
	if err != nil {
		log.Fatal(err)
	}
	defer infile.Close()

	char := make([]byte, 3)
	infile.Read(char)
	if strings.TrimSpace(string(char)) != "P6" {
		fmt.Printf("Error: wrong type of ppm format, found %s need P6\n", strings.TrimSpace(string(char)))
		os.Exit(1)
	}
	first_line_arr := getWordsInLine(infile)
	x_pixel_width, _ := strconv.Atoi(first_line_arr[0])
	y_pixel_width, _ := strconv.Atoi(first_line_arr[1])
	fmt.Printf("x pixels: %d y pixels: %d\n", x_pixel_width, y_pixel_width)

	second_line := getWordsInLine(infile)
	fmt.Printf("Second line stuff: %v\n", second_line)

	reader := bufio.NewReader(infile)
	//Red 3 bytes: RGB alltogheter
	char = make([]byte, 3)
	var data []string

	for i := 0; ; i++ {

		//n, err := reader.Read(char) // Does not read exactly len(char) bytes
		n, err := io.ReadFull(reader, char) //Read exactly len(char) bytes and returns error in case of eof
		if err != nil {
			if err != io.EOF {
				fmt.Println(err)
			}
			fmt.Printf("Eof at %d\n", i)
			break
		}
		if n != 3 {
			fmt.Printf("less then 3 byte read in %d with this error %d \n", i, err)

		}
		if string(char) == "\n" {
			fmt.Printf("endl at %d\n", i)
			break
		}
		//value := uint64(uint(char[2])<<16 | uint(char[1])<<8 | uint(char[0]))
		value := uint32(uint(char[2])<<16 | uint(char[1])<<8 | uint(char[0]))
		data = append(data, fmt.Sprintf("%X", value))
	}
	fmt.Printf("First 13 RGB bytes:\n%v\n", data[:13])

	outfile, err := os.Create(output_hex_path)
	if err != nil {
		log.Fatal(err)
	}
	defer outfile.Close()

	w := bufio.NewWriter(outfile)
	for _, value := range data {
		str := fmt.Sprintf("%s\n", value)
		w.WriteString(str)
	}
	w.Flush()
}

func getWordsInLine(infile *os.File) []string {
	char := make([]byte, 1)
	var line string
	for infile.Read(char); string(char) != "\n"; infile.Read(char) {
		line += string(char)
	}
	return strings.Fields(line)
}
