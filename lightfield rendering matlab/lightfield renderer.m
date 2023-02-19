%%%virtual image distance:
dv = 10; %mm
virtual_image = True;

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

%translation vectors - rectangular lenses
%{
t1 = [7,0]; %mm
t2 = [0,5.4]; %mm
%}

%pixel density along these vectors
p1 = pix_density.*t1; %pixel/lens along vector
p2 = pix_density.*t2; %pixel/lens along vector
lp1 = sqrt(sum(p1.^2));
lp2 = sqrt(sum(p2.^2));

%%% distance lens-lcd
if virtual_image==True
    d = dv*f/(dv+f);
elseif virtual_image==False
    d = dv*f/(dv-f);
    dv = -dv;
else
    fprintf('wrong setup for virtual_image: please input True or False\n');
end

fprintf('adjust lens to distance d = %.3f mm\n',d);
offset_scaling = dv/d;

%%%picture
%load picture
img = imread('Zebra.png');
pic = sum(img,3); pic = pic/max(pic(:));
shape = shape(pic);

%image scaling (constant virtual width wv)
wv = 20; %mm
pix_density_v = (pic.shape[1])/wv; %%pixel/mm
s = 1/pix_density[1] * pix_density_v /2; %pixel/pixel

%image shift (number of LCD pixel)
x_shift = 900; %px
y_shift = 600; %px

%%% pixel array:
result = zeros(res[0],res[1]);
%for each pixel on lcd, find lens to pass through and pixel offset
xx,yy = meshgrid(1:res[1],1:res[0]); %coordinate grid
p2_lens = round(yy./p2[1]);
y_offset = yy - p2[1]*p2_lens;
x_offset = xx - p2[0]*p2_lens;
p1_lens = round(x_offset./p1[0]);
x_offset = x_offset - p1[0]*p1_lens;

border = (x_offset.^2 + y_offset.^2) > ((abs(x_offset)-p2[0]).^2 + (abs(y_offset)-p2[1]).^2);
p2_lens = p2_lens + sign(p2_lens)*border;
y_offset = y_offset - sign(y_offset)*p2[1] * border;
x_offset = x_offset - sign(x_offset)*p2[0] * border;
grid = x_offset.^2 + y_offset.^2;

%calculate virtual pixel x_0 from LCD pixel x_n (subtract offset from lens middle pixel and add offset scaled by image equation)
%afterwards scaling with s (to compensate for the pixel density difference between the given image and the LCD)
x_pix = (xx - x_shift - x_offset + x_offset*offset_scaling)*s;
y_pix = (yy - y_shift - y_offset + y_offset*offset_scaling)*s;

%images outside of given image are not interpolated, since they are zero
mask = ( (y_pix<(shape[0]-1)).*(y_pix>0) ) .* ( (x_pix<(shape[1]-1)).*(x_pix>0) );
idx = where(mask);

%interpolate color at virtual pixel
from scipy.interpolate import RegularGridInterpolator
interpolation = RegularGridInterpolator(1:shape[1], 1:shape[0], pic.T, method='linear');%method='nearest'
result[idx] = interpolation((x_pix[idx],y_pix[idx]));

result = rescale(result);
imsave(['zebra_dv_'+str(dv)+'_d_'+str(d)+'_f_'+str(f)+'.png'],result);

% display results
figure(1); title('original'); imshow(pic);
figure(2); title('grid'); imshow(grid);
figure(3); title('mapping'); imshow(sqrt( x_pix.^2 + y_pix.^2 ));
figure(4); title('coverage'); imshow(mask.astype(int));
figure(5); title('rendered'); imshow(result);