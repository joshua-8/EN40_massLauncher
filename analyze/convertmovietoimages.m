function convertmovietoimages

% Edit the lines below to change the directories where data gets read/saved
%
% By default, a new directory called
% Masslauncher_Image_Files/test1/ will be created
% The image files will be called 0001.jpg, 0002.jpg, 0   003.jpg, etc
% in sequence
%
workingDir = 'Masslauncher_Image_Files';
subDir = 'test1';
mkdir(workingDir)
mkdir(workingDir,subDir)

impactVideo = [];
movieFileName = 'DSC_0057.MOV'; % Default file name



while (isempty(impactVideo))

    try
        impactVideo = VideoReader(movieFileName);
    catch Except    
        f = msgbox({'The file '; movieFileName; ' was not found ';...
    'Please use the browser to select the .MOV file to be processed' });
        uiwait(f);
        movieFileName = uigetfile('*.MOV');
    end
end

f = waitbar(0,'Processing video');

ii = 1;
d = impactVideo.Duration;
while hasFrame(impactVideo)
   img = readFrame(impactVideo);
   filename = [sprintf('%04d',ii) '.jpg'];
   fullname = fullfile(workingDir,subDir,filename);
   imwrite(img,fullname)    % Write out to a JPEG file (img1.jpg, img2.jpg, etc.)
   waitbar(impactVideo.CurrentTime/d,f)
   ii = ii+1;
end
close(f);
filename = 'image_numbers.jpg';
fullname = fullfile(workingDir,subDir,filename);
f = msgbox({'Video to image conversion completed '; ...
['Images were saved to ',fullname] });
uiwait(f);   


end