warning off;
close all;
clear all;
clc;

%% load video

disp('************************');
disp('***** Videos  **********');
disp('1 Basketball');
disp('2 Deer');
disp('3 HighJump');
disp('4 Tennis');
disp('5 Basketball');
disp('6 Tennis');
disp('7 Weightlifting');
disp('8 Cricket');
disp('9 Swimming');
disp('10 Swimming');
disp('11 Deer');
disp('12 Weightlifting');

disp('************************');
x=input('To Enter Video Number');

if(x==1)
    
load basketball
inpbas
    
%% Threshold image

I = rgb2hsv(b22);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);


%% Blob Analysis

hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea',200,...
    'MaximumBlobArea',5000);
[objArea,objCentroid,bboxOut] = step(hBlobAnalysis,Ibwopen);


%% Convolutional Neural Network 

%% Total number of layers

numLayers = 8; 

%% Number of subsampling layers

numSLayers = 3; 

%% Number of convolutional layers

numCLayers = 3; 

%% Number of fully-connected layers

numFLayers = 2;

%% Number of input images 

numInputs = 1; 

%% Image width

InputWidth = 512; 

%% Image height

InputHeight = 512;

%% Number of outputs

numOutputs = 10; 

%% Create an empty convolutional neural network with deined structure

sinet = cnn(numLayers,numFLayers,numInputs,InputWidth,InputHeight,numOutputs);

%% network performances

sinet.SLayer{1}.SRate = 1;
sinet.SLayer{1}.WS{1} = ones(size(sinet.SLayer{1}.WS{1}));
sinet.SLayer{1}.BS{1} = zeros(size(sinet.SLayer{1}.BS{1}));
sinet.SLayer{1}.TransfFunc = 'purelin';



%% histogram

b22=rgb2gray(b22);
figure;imhist(b22);
title('histogram');
%% 

BW = b22 < 190;  

%% edge detection

BWe = edge(b22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

%% RNN LSTM

simustep=0.001; 
theta=4; 
x1=4; 
x2=0; 
c=[0 1 0]'; 
y=[20 20 0.01]'; 
z2=[0 0 0]'; 
mu=0.25;
t=0; 
j=1; 
for i=0:150000 
    A2=[1 -sign(y(1)) 0;-20*(x1-5)*x2/(y(1)) 0 0;0 0 y(1)]; 
    ratelast=-20*(x1-5)*x2; 
    b2=[0 ratelast ratelast]'; 
    dy=-mu*[c*(c'*y-b2'*z2)+A2'*(A2*y-b2)]; 
    dz2=-mu*[-b2*(c'*y-b2'*z2)+A2*(A2'*z2-c)]; 
    y=y+dy*simustep; 
    z2=z2+dz2*simustep; 
    dtheta=y(3); 
    theta=theta+dtheta*simustep; 
    u=-30*(x1-theta)-11*x2; 
    dx2=u; 
    x2=x2+dx2*simustep; 
    dx1=x2; 
    x1=x1+dx1*simustep; 
    yout=-10*(x1-5)^2+10;  
    t=t+simustep; 
    if (mod(i,50)==0) 
            ddy1(j)=dy(1); 
            ddy2(j)=dy(2); 
            ddy3(j)=dy(3); 
            yy1(j)=y(1); 
            yy2(j)=y(2); 
            yy3(j)=y(3); 
            thetaout(j)=theta; 
            uu(j)=u; 
            xx2(j)=x2; 
            xx1(j)=x1; 
            fmin(j)=yout;                                 
            tt(j)=t; 
            j=j+1; 
     end; 
 end; 
 
 disp(ss1);
 disp(ss2);
 disp(ss3);
 disp(ss4);
 disp(ss5);
 disp(ss6);
 disp(ss);

else if(x==2)
        load deer
        inpdeer
        %% histogram
%% Threshold image

I = rgb2hsv(d22);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(d22);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss8);
disp(ss9);
disp(ss10);
disp(ss7);

    else if(x==3)
            load highjump
            inphig
            %% Threshold image

I = rgb2hsv(h52);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

h52=rgb2gray(h52);
figure;imhist(h52);
title('histogram');
%% 

BW = h52 < 190;  

%% edge detection

BWe = edge(h52,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(s11);
disp(s12);
disp(s13);
disp(s14);
disp(s15);
disp(s16);
disp(s17);

        else if(x==4)
                load tennis
                inpten
                I = rgb2hsv(t52);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

t52=rgb2gray(t52);
figure;imhist(t52);
title('histogram');
%% 

BW = t52 < 190;  

%% edge detection

BWe = edge(t52,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(s18);
disp(s19);
disp(s20);
disp(s21);
disp(s22);
disp(s23);

else if(x==5)
                load bak
                inbak
                I = rgb2hsv(bk52);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

t52=rgb2gray(bk52);
figure;imhist(t52);
title('histogram');
%% 

BW = t52 < 160;  

%% edge detection

BWe = edge(t52,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
% Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);
% 
% 
% %% Green color
% 
% idx_g = find(Hue_s >= 0.1);
% Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);
% 
% %% 
% 
% BW_b = ~ismember(BWl, [idx_s 0]); 

disp(s18);
disp(s19);
disp(s20);
disp(s21);


else if(x==6)
        load tenn
        inten
        %% histogram
%% Threshold image

I = rgb2hsv(te22);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(te22);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss8);
disp(ss9);
disp(ss10);
disp(ss11);
%disp(ss12);
       
else if(x==7)
        load weig
        inweig
        %% histogram
%% Threshold image

I = rgb2hsv(weig22);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(weig22);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss8);
disp(ss9);
disp(ss10);
disp(ss11);
disp(ss12);
else if(x==8)
        load cricket
        incrk
        %% histogram
%% Threshold image

I = rgb2hsv(crk113);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(crk113);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss13);
disp(ss14);
disp(ss15);
disp(ss16);
disp(ss17);
else if(x==9)
        load swimming
        inswim
        %% histogram
%% Threshold image

I = rgb2hsv(swim80);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(swim80);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss18);
disp(ss19);
disp(ss20);
else if(x==10)
        load swiming
        inswi
        %% histogram
%% Threshold image

I = rgb2hsv(swi80);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(swi80);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss21);
disp(ss22);
disp(ss23);
else if(x==11)
        load deer1
        inde
        %% histogram
%% Threshold image

I = rgb2hsv(de80);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(de80);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss24);
disp(ss25);
disp(ss26);
disp(ss27);
disp(ss28);
else if(x==12)
        load weight1
        inweig1
        %% histogram
%% Threshold image

I = rgb2hsv(wei180);
figure,imshow(I)
title('hsv Color');

%% Define thresholds for channel 1 based on histogram settings

channel1Min = 0.379;
channel1Max = 0.496;

%% Define thresholds for channel 2 based on histogram settings

channel2Min = 0.436;
channel2Max = 1.000;

%% Define thresholds for channel 3 based on histogram settings

channel3Min = 0.000;
channel3Max = 1.000;

%% Create mask based on chosen histogram thresholds

BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);



%% Remove disturbances

diskElem = strel('disk',3);
Ibwopen = imopen(BW,diskElem);

d22=rgb2gray(wei180);
figure;imhist(d22);
title('histogram');
%% 

BW = d22 < 190;  

%% edge detection

BWe = edge(d22,'canny',[0.04 0.06]); 

%% image regions and holes

BWf1 = imfill(BWe, 'holes');


%% Morphological operations

BWb = bwmorph(BWf1, 'bridge');

%% image regions and holes

BWf2 = imfill(BWb, 'holes');

%% Morphological operations

BWo = bwmorph(BWf2, 'open');  


%% Label connected components

BWl = bwlabel(BWo);          

%% calculate Bounding Box

stats=regionprops(BWl, 'Area', 'Centroid', 'BoundingBox');
stats(1);

%% Rectangle

idx_s = find([stats.Area] < 1500);  
stats_s = stats(idx_s);
I_s = insertShape(I,'FilledRectangle',[cat(1,stats_s.BoundingBox)]);

%% Position calculation

pos = uint32([cat(1,stats_s.Centroid)]);     
pos = [cat(1,stats_s.Centroid)];
I_sc = insertMarker(I, pos, 'Size', 5);

%%  filter

f = fspecial('average', 7);
Iave = imfilter(I, f);

%%  image pixel

RGB_s = impixel(Iave, pos(:,1), pos(:,2));   


%% hue saturation color

HSV_s = rgb2hsv(RGB_s); Hue_s = HSV_s(:,1); 

%% Red color box detect

idx_r = find(Hue_s < 0.1);
Iresult1 = insertObjectAnnotation(I, 'rectangle', [cat(1,stats_s(idx_r).BoundingBox)], 'RED', 'Color', 'red', 'TextBoxOpacity', 1);


%% Green color

idx_g = find(Hue_s >= 0.1);
Iresult2 = insertObjectAnnotation(Iresult1, 'rectangle', [cat(1,stats_s(idx_g).BoundingBox)], 'GREEN', 'Color', 'green', 'TextBoxOpacity', 1);

%% 

BW_b = ~ismember(BWl, [idx_s 0]); 

disp(ss29);
disp(ss30);
disp(ss31);
disp(ss32);

    end

    end
    end
    end
    end
    end
    end
    end
            end
        end
    end
end

