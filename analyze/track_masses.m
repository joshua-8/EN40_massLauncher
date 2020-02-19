function track_masses
%   ENGN0040 Dynamics and Vibrations
%   School of Engineering Brown University
%
%
%   Script to track the motion of a user-defined sub-region within an image
%   (the 'correlation template') through subsequent frames of a movie.
%   The position of a reference point in the correlation template
%   is plotted as a function of time.
%
%   The script uses the normxcorr2 function and cpcorr functions
%   from the image processing toolbox to search for and locate the
%   set of pixels in each image that best match those in the correlation
%   template.   For the tracking to work, the user must select a
%   correlation template that is expected to look very similar in 
%   each frame of the movie.
%
%
%
    clear all;
    close all;

    %% Test information
    fps         = 1200;       % camera frame rate (frames/sec)
    dt          = 1/fps;      % frame time spacing
    scale_spacing = .50;   % physical spacing between scale marks, m 

    % Edit the line below to specify the directory containing the image
    % You must create the images from the raw movie file before running
    % this script
    test_direc = 'Masslauncher_Image_Files/test1/';
    csvfilename = 'mass_launcher_test_data2.csv';

 
    imnames = dir([test_direc '*.jpg']);
 
    while (isempty(imnames))
        f = msgbox({'The directory '; test_direc; ' was not found or contained no images ';...
    'Please use the browser to select the directory containing image files' });
        uiwait(f);
        test_direc = uigetdir;
        imnames = dir([test_direc '\*.jpg']);
    end

    dtick = calibrate_camera(imnames,test_direc);  % # pixels between marks
    pixpercm =  dtick/scale_spacing;

    [firstframe,lastframe] = selectFrameRange(imnames,test_direc);
  
    time = firstframe/fps:dt:lastframe/fps;   

%% Main loop
%  tracks user-selected region through successive images and displays 
%  position-v-time plot. User can accept or reject data, then is offered a
%  choice of tracking another region or quitting and saving data
 
    loopflag = true;
    data = [];
    while loopflag
        [frames,xpix,ypix] = mass_tracker(firstframe,lastframe,imnames,test_direc);
        if (length(data)>0)
            data_new = [data,xpix'];
        else
            data_new = xpix';
        end
        close all
        posfigure = figure;
        axes1 = axes('Parent',posfigure,'YGrid','on','XGrid','on','FontSize',14,...
        'Position',[0.13 0.3 0.775 0.63]);
        grid on
        box(axes1,'on');
        hold(axes1,'on');
        ylabel('Position (cm)');
        xlabel('Time (seconds)');
        title('Mass position -v- time');  
        plot(time,data_new/pixpercm)
        
        uicontrol('Style','pushbutton','String','Accept new data',...
            'pos',[5 0 150 30], 'parent',posfigure,'CallBack',@accept,...
            'UserData',1);
        uicontrol('Style','pushbutton','String','Delete new data',...
            'pos',[5 32 150 30], 'parent',posfigure,'CallBack',@reject,...
            'UserData',1);       
        uiwait(gcf);       
        close all;
        filename = [test_direc,'/',imnames(firstframe).name];
        I = imread(filename);
        h = figure;
        uicontrol('Style','pushbutton','String','Track another mass',...
            'pos',[5 0 150 30], 'parent',h,'CallBack',@nextmass,...
            'UserData',1);
        uicontrol('Style','pushbutton','String','Save data and quit',...
            'pos',[5 32 150 30], 'parent',h,'CallBack',@quit,...
            'UserData',1);
        imshow(I,'InitialMagnification',200);
        uiwait(gcf);
    end
    close all
    
    csvwrite(csvfilename,[time',data/pixpercm]);

    f = msgbox({'Image processing completed '; ...
    ['Data was saved to ',csvfilename] });
    uiwait(f);   
    
    
%   Callbacks for buttons
    function nextmass(~,~)
       loopflag = true;
       uiresume(gcf);
    end
    function quit(~,~)
       loopflag = false;
       uiresume(gcf);
    end
    function accept(~,~)
       data = data_new;
       uiresume(gcf);
    end
    function reject(~,~)
       uiresume(gcf);
    end

end

function dtick = calibrate_camera(filenames,foldername)
%   Function to determine # pixels between scale marks
%   User must select the scale marks
    filename = [foldername,'/',filenames(1).name];
    I = imread(filename);
    figure
    imshow(I,'InitialMagnification',200);
    hold on;
    title('Click on 2 scale marks to calibrate the camera')
    [xtick_space,ytick_space] = ginput(2);
    dtick   = sqrt( (xtick_space(2)-xtick_space(1)).^2 + (ytick_space(2)-ytick_space(1)).^2 );
    close all;
end

function [firstframe,lastframe] = selectFrameRange(filenames,foldername)
%   Function to allow user to scroll through frames to select
%   first and last frames for tracking

    %% Let the user select an approximate start frame
    h = figure;
    uicontrol('Style','pushbutton','String','Press to select approx start frame',...
            'pos',[5 0 300 40], 'parent',h,'CallBack',@finish);
    continue_running = true;
    frameNumber = 10;  % Start at frame number 10;
    
    while (continue_running)  % Keep showing images until user selects one
      frameNumber= frameNumber + 10;
      filename = [foldername,'/',filenames(frameNumber).name];
      I = imread(filename);
      imshow(I,'InitialMagnification',200);
      title(['Frame ',num2str(frameNumber)]);
      pause(0.01);
    end
    close all
%   Give the user buttons to step through frames and select one
    h = figure;
    uicontrol('Style','pushbutton','String','Select',...
            'pos',[5 0 50 30], 'parent',h,'CallBack',@select,...
            'UserData',1);
    uicontrol('Style','pushbutton','String','Previous',...
            'pos',[5 32 50 30], 'parent',h,'CallBack',@previous,...
            'UserData',1);
    uicontrol('Style','pushbutton','String','Next',...
            'pos',[5 64 50 30], 'parent',h,'CallBack',@next,...
            'UserData',1);

    filename = [foldername,'/',filenames(frameNumber).name];
    I = imread(filename);
    imshow(I,'InitialMagnification',200);    
    title('Use the buttons to select the start frame')

    uiwait(gcf) % Wait for user to select a frame
    firstframe = frameNumber; % First frame has been selected

    close all    

    %% Let the user select an approximate end frame
    h = figure;
    uicontrol('Style','pushbutton','String','Press to select approx end frame',...
            'pos',[5 0 300 40], 'parent',h,'CallBack',@finish,...
            'UserData',1);
    continue_running = true;
    frameNumber = firstframe+10;
    while (continue_running) % Keep cycling until the user selects a frame
      frameNumber = frameNumber + 1;
      filename = [foldername,'/',filenames(frameNumber).name];
      I = imread(filename);
      imshow(I,'InitialMagnification',200);
      title(['Frame ',num2str(frameNumber)])
      pause(0.01);
    end
    
    close all
    h = figure;
    uicontrol('Style','pushbutton','String','Select',...
            'pos',[5 0 50 30], 'parent',h,'CallBack',@select,...
            'UserData',1);
    uicontrol('Style','pushbutton','String','Previous',...
            'pos',[5 32 50 30], 'parent',h,'CallBack',@previous,...
            'UserData',1);
    uicontrol('Style','pushbutton','String','Next',...
            'pos',[5 64 50 30], 'parent',h,'CallBack',@next,...
            'UserData',1);
    filename = [foldername,'/',filenames(frameNumber).name];
    I = imread(filename);
    imshow(I,'InitialMagnification',200);      
    title(['Use the buttons to select the end frame'])
    uiwait(gcf);
    lastframe = frameNumber;
    close all

%   Callbacks for buttons    
    function finish(~,~)
       continue_running = false;
    end

    function next(~,~)
       frameNumber = frameNumber + 1;
       filename = [foldername,'/',filenames(frameNumber).name];
       I = imread(filename);
       imshow(I,'InitialMagnification',200);
       title(['Frame ',num2str(frameNumber)])
    end

    function previous(~,~)
       frameNumber = frameNumber - 1;
       filename = [foldername,'/',filenames(frameNumber).name];
       I = imread(filename);
       imshow(I,'InitialMagnification',200);
       title(['Frame ',num2str(frameNumber)])
    end

    function select(~,~)
       uiresume(gcf);
    end

end  

function [frames,x_tracked_point,y_tracked_point] = mass_tracker(firstframe,lastframe,filenames,foldername)
%  mass_tracker finds the position of the masses in pixels.
%   foldername        = name of folder the images are in.
%   filenames         = vector of names of image filenames (in sequence)
%   firstframe        = start frame for tracking
%   lastframe         = last frame to be tracked
%   frames            = list of frames for each point
%   x_tracked_point   = vector of x positions of tracked point in each frame, in pixels
%   y_tracked_point   = vector of y positions of tracked point in each frame, in pixels
%   The origin is at the top left corner of the image

    %%  Read the first image and determine its size
    filename = [foldername,'/',filenames(firstframe).name];
    I        = imread(filename);
    [vsize,hsize]    = size(I);
%
%   Get the correlation template from the reference image
%   xc(1:2)   horizontal coords of lower and upper corner
%   yc(1:2)   vertical coords of lower and upper corner
%   x0,y0     horizontal/vertical coords of reference point
%
    [xc,yc,x0,y0] = corr_template_select(I);  


%   Crop the reference image
    vlo = max(floor(yc(1)),1);
    vhi = min(ceil(yc(2)),vsize);
    hlo = max(floor(xc(1)),1);
    hhi = min(ceil(xc(2)),hsize);
    ref_image = I(vlo:vhi,hlo:hhi);
%   Remember center of reference image and coords of the ref point    
    h_center = (hlo+hhi)/2;
    v_center = (vlo+vhi)/2;
    refpoint_x_relative = x0 - hlo;
    refpoint_y_relative = y0 - vlo;

%   These specify the size of the image that will be cropped from the
%   current image and searched for correlation with ref. image
%   It should be larger than the reference image.
    vsize_cur = 2*(vhi-vlo);
    hsize_cur = 2*(hhi-hlo);

%% 
%   The first coord is just the position of the ref point in the start image    
    x_tracked_point(1) = x0;
    y_tracked_point(1) = y0;
    frames(1) = firstframe;
%   Now find the ref image in all subsequent images    
    k=2;
    for i=firstframe+1:lastframe
        filename = [foldername,'/',filenames(i).name];  % Read the next image
        curr_image = imread(filename);
        
% Crop a region from the current image around expected location of point being tracked
        vlo = max(floor(v_center)-vsize_cur,1);
        vhi = min(floor(v_center)+vsize_cur,size(curr_image,1));
        hlo = max(floor(h_center)-hsize_cur,1);
        hhi = min(floor(h_center)+hsize_cur,size(curr_image,2));
        cursubimage = curr_image(vlo:vhi,hlo:hhi);
        
% Get the correlation
        C = normxcorr2(ref_image,cursubimage);
        [vpeak,hpeak] = find(C==max(C(:)));
%   The coords of the top left corner of the ref image in the current image
        voffset = vpeak-size(ref_image,1);
        hoffset = hpeak-size(ref_image,2);
%   Coords of the user selected ref point relative to top left of curr image
        x = hoffset + refpoint_x_relative + hlo; 
        y = voffset + refpoint_y_relative + vlo;
%   Adjust points using cpcorr for sub-pixel resolution        
        adjustedpoints = cpcorr([x,y],[x0,y0],curr_image(:,:,1),I(:,:,1));
%   Store the new point
        x_tracked_point(k) = adjustedpoints(1);
        y_tracked_point(k) = adjustedpoints(2);
%   Update center of cropped image for next frame
        h_center = h_center + x_tracked_point(k)-x_tracked_point(k-1);
        v_center = v_center + y_tracked_point(k)-y_tracked_point(k-1);        
%   Show the current position of the tracked point
        hold off
        imshow(curr_image,'InitialMagnification',200)
        hold on
        plot(x_tracked_point(k),y_tracked_point(k),'gx','markersize',12,'linew',2)
        pause(0.05);
        k=k+1;
    end
end

function [xc,yc,xi,yi] = corr_template_select(I)

    figure;
    clf;
    imshow(I,'InitialMagnification',200);
    hold on;

    title('Select upper left, then lower right corner of correlation template box');
    [xc,yc] = ginput(2);   % Collect the clicks
%   If user selects corners wrong switch them
    if (xc(2)<xc(1))
        xx = xc(2);
        xc(2) = xc(1);
        xc(1) = xx;
    end
    if (yc(2)<yc(1))
        yy = yc(2);
        yc(2) = yc(1);
        yc(1) = yy;
    end
    %  Display correlation template as a red rectangle
    plot([xc(1),xc(2),xc(2),xc(1),xc(1)],[yc(1),yc(1),yc(2),yc(2),yc(1)],'r-','linew',2)

    title('Select reference point inside template box');
    [xi,yi] = ginput(1);
    plot(xi,yi,'bx','linew',2,'markersize',10)
    close;
end
