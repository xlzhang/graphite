function [ ppvid, background ] = vidpreproc(vid, etime, outpath)
%VIDPREPROC Bee tag pipeline video preprocessor
%   Extracts the active region from a given video file and generates a
%   background image of the active region. The active region is determined
%   by computing the variance of image pixels over time. A full-width and
%   partial height video is saved (.mj2) if the active region is
%   successfully detected. The background image is generated by computing
%   the mean of image pixels over time. A background image (.png) is saved
%   for the active region (if detected) or the entire video region.
%
%   SYNTAX
%   [ ppvid, background ] = vidpreproc(vid, etime, outpath)
%
%   DESCRIPTION
%   [ ppvid, background ] = vidpreproc(vid, etime, outpath) accesses the
%   video specified by the video handle vid, and computes the active region
%   and background image from the videos current time to the end time
%   specified by etime. The output files are written to the directory
%   specified by outpath. This function returns the preprocessed video
%   handle and the background image. If the active region was not detected,
%   ppvid is set to vid.
%
%   AUTHOR
%   Blair J. Rossetti
%
%   DATE LAST MODIFIED
%   2016-05-10

% check MATLAB version
legacy = verLessThan('matlab', '9.0');

% get video info
stime = vid.CurrentTime;
[~,name, ~] = fileparts(vid.Name);

% calculate mean for background
numFrames = 1;
meanImg = double(readFrame(vid));

while hasFrame(vid) && vid.CurrentTime <= etime
    meanImg = meanImg + double(readFrame(vid));
    numFrames = numFrames + 1;
end
meanImg = meanImg./numFrames;

% reset CurrentTime
vid.CurrentTime = stime;

% calculate variance for active region
varImg = (double(readFrame(vid)) - meanImg).^2;

while hasFrame(vid) && vid.CurrentTime <= etime
    varImg = varImg + (double(readFrame(vid)) - meanImg).^2;
end
varImg = varImg./(numFrames-1);

% reset CurrentTime
vid.CurrentTime = stime;

% convert to grayscale
varImg = rgb2gray(mat2gray(varImg));

% threshold
if legacy
    mask = im2bw(varImg, graythresh(varImg));
else
    mask = imbinarize(varImg);
end

% clean mask
mask = imdilate(mask,strel('square',3));
mask = imfill(mask, 'holes');

% get bbox of largest object
stats = regionprops(mask,'Area', 'BoundingBox');
[~,idx] = max([stats.Area]);
bbox = round(stats(idx).BoundingBox);

% extract active region
if bbox(4)/size(varImg,1) > 0.05 && bbox(4)/size(varImg,1) < 0.99 && bbox(2) < size(varImg,1)/3
    % create preprocessed video
    ppvidpath = fullfile(outpath,[name '_preprocessed.mj2']);
    ppvid = VideoWriter(ppvidpath,'Archival');
    open(ppvid)
    while hasFrame(vid) && vid.CurrentTime <= etime
        frame = readFrame(vid);
        writeVideo(ppvid, frame(bbox(2):bbox(2)+bbox(4)-1,:,:))
    end
    close(ppvid)

    % reset CurrentTime
    vid.CurrentTime = stime;

    % define background image
    background = uint8(meanImg(bbox(2):bbox(2)+bbox(4)-1,:,:));
    imwrite(background, fullfile(outpath,[name '_background.png']));
   
    % get preprocessed video handle
    ppvid = VideoReader(ppvidpath);
else
    % define background image
    background = uint8(meanImg);
    imwrite(background, fullfile(outpath,[name '_background.png']));
    
    % use raw video
    ppvid = vid;
end %if-else

end %function    
