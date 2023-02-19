close all; clear; clc;

%%%virtual image distance:
dv = 10; %mm
virtual_image = true;

%%%lcd parameters (LS055R1SX03)
res = [1440,2560]; %pixel
%res = [1440,2880]; %pixel
dim = [68.04,120.96]; %mm
%dim = 25.4/554*res; %mm
pix_density = res./dim; %pixel/mm

%%%lens parameters
%size: 66 x 63.6 x 12 (10.7)

%focal length
f = 6.5; %mm
%f = 41.9; %mm

%translation vectors - hexagonal lenses
a = 3.5; %mm
t1 = [1,0]*a; %mm
t2 = [cos(2*pi/6),sin(2*pi/6)]*a; %mm

%{
%translation vectors - rectangular lenses
t1 = [7,0]; %mm
t2 = [0,5.4]; %mm
%}

%test alignment of t1 with x-axis
if t1(2)>0
    error('t1(2) has to be zero for algorithm to work !');
end

%pixel density along these vectors
p1 = pix_density.*t1; %pixel/lens along vector
p2 = pix_density.*t2; %pixel/lens along vector
lp1 = sqrt(sum(p1.^2));
lp2 = sqrt(sum(p2.^2));

%%% distance lens-lcd
if virtual_image==true
    d = dv*f/(dv+f);
elseif virtual_image==false
    d = dv*f/(dv-f);
    dv = -dv;
else
    fprintf('wrong setup for virtual_image: please input true or false\n');
end

fprintf('adjust lens to distance d = %.3f mm\n',d);
offset_scaling = dv/d;

%%%picture
%load picture
pic = imread('Zebra.png');
img = sum(pic,3);
img = img/max(img(:));
img = double(img <0.8); %binary flip colors
shape = size(img);

%image scaling (constant virtual width wv)
wv = 20; %mm
pix_density_v = shape(2)/wv; %%pixel/mm
s = 1/pix_density(2) * pix_density_v /2; %pixel/pixel

%image shift (number of LCD pixel)
x_shift = 900; %px
y_shift = 600; %px

%%% pixel array:
result = zeros(res(1),res(2));
%for each pixel on lcd, find lens to pass through and pixel offset
[xx,yy] = meshgrid(1:res(2),1:res(1)); %coordinate grid
p2_lens = round(yy./p2(2));
y_offset = yy - p2(2)*p2_lens;
x_offset = xx - p2(1)*p2_lens;
p1_lens = round(x_offset./p1(1)); %lens number in x-direction
x_offset = x_offset - p1(1)*p1_lens; %coordinates inside lens in x-direction
border = (x_offset.^2 + y_offset.^2) > ((abs(x_offset)-p2(1)).^2 + (abs(y_offset)-p2(2)).^2);
p2_lens = p2_lens + sign(p2_lens).*border;
y_offset = y_offset - sign(y_offset)*p2(2).*border;
x_offset = x_offset - sign(x_offset)*p2(1).*border;

%calculate virtual pixel x_0 from LCD pixel x_n (subtract offset from lens middle pixel and add offset scaled by image equation)
%afterwards scaling with s (to compensate for the pixel density difference between the given image and the LCD)
x_pix = (xx - x_shift - x_offset + x_offset*offset_scaling)*s;
y_pix = (yy - y_shift - y_offset + y_offset*offset_scaling)*s;

%images outside of given image are not interpolated, since they are zero
mask = ( (y_pix<(shape(1)-1)).*(y_pix>0) ) .* ( (x_pix<(shape(2)-1)).*(x_pix>0) );
idx = find(mask);

%interpolate color at virtual pixel
result(idx) = interp2(img,x_pix(idx),y_pix(idx));
result = result/max(abs(result(:)));
imwrite(result,['zebra_dv_',num2str(dv),'_d_',num2str(d),'_f_',num2str(f),'.png']);

% display results
figure(1); title('original'); imshow(pic);
figure(2); title('grid'); imagesc(sqrt(x_offset.^2 + y_offset.^2));
figure(3); title('mapping'); imagesc(sqrt( x_pix.^2 + y_pix.^2 ));
figure(4); title('coverage'); imagesc(mask);
figure(5); title('rendered'); imagesc(result);
