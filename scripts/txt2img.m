clear
fid = fopen('imageo.txt','r+');

line = fgetl(fid);
uns16 = sscanf(line, '%d');
y_size = double(uns16);
line = fgetl(fid);
uns16 = sscanf(line, '%d');
x_size = double(uns16);

for y = 1 : y_size , 
   for x = 1 : x_size , 
     signed = fscanf(fid, '%2x',1);
       E(y,x) = uint8(signed); 
   end
end

imwrite(E, 'imageo.jpg','jpg','Quality',100);
fclose(fid);

%%%%%%%%%%%%%%%
clear
fid = fopen('imagee.txt','r+');

line = fgetl(fid);
uns16 = sscanf(line, '%d');
y_size = double(uns16);
line = fgetl(fid);
uns16 = sscanf(line, '%d');
x_size = double(uns16);

for y = 1 : y_size , 
   for x = 1 : x_size , 
     signed = fscanf(fid, '%2x',1);
       E(y,x) = uint8(signed); 
   end
end

imwrite(E, 'imagee.jpg','jpg');
fclose(fid);