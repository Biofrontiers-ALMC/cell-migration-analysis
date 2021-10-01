classdef CMTrack < handle
    %CMTRACK  Class to track cells in movies
    %
    %  OBJ = CMTRACK will create a new CMTRACK object to process time-lapse
    %  movies. 
    
    properties
        
        ChannelToTrack = 1;
        ExportVideo = true;
        ThresholdLvl = 1800;
        LinkRange = [0 15];
        
    end
    
    methods
        
        function createExclusionMask(obj, files, varargin)
            %CREATEEXCLUSIONMASK  Create masks specifying exclusion regions
            %
            %  CREATEEXCLUSIONMASK(OBJ, FILES) allows the user to create a
            %  mask indicating the region to exclude for each file
            %  specified in the cell array FILES. The maximum intensity
            %  projection (MIP) of each image will be displayed. To create
            %  an exclusion mask, draw a rectangle by dragging across the
            %  figure window. When you are happy with the mask, return to
            %  the Command Window and press any key to continue.
            %
            %  The exclusion masks will be saved in the same directory with
            %  as the original file with the suffix '_exm.tif'. If present,
            %  these files will be used for tracking cells with the method
            %  'process'. Additionally, the number of detected objects
            %  within the exclusion region will also be counted.
            %
            %  CREATEEXCLUSIONMASK(..., CT) will display the image
            %  specified by a 1x2 vector CT = [iC, iT] where iC is the
            %  channel, and iT is the frame/timepoint specifying the image.
            
            if ischar(files) || isstring(files)
                files = {files};
            elseif ~iscellstr(files)
                error('CMTrack:createExclusionMask:InvalidInputFormat',...
                    'The files input must be a char array, string, or a cell of strings.')
            end
            
            if isempty(varargin)
                ct = [1, 1];
            else
                ct = varargin{1};
            end            
            
            for iF = 1:numel(files)
                
                reader = BioformatsImage(files{iF});
                
                %Compute the maximum intensity projection
                MIP = zeros(reader.height, reader.width, ...
                    reader.sizeZ, 'uint16');
                
                for iZ = 1:reader.sizeZ
                    
                    MIP(:, :, iZ) = getPlane(reader, iZ, ct(1), ct(2));
                    
                end
                MIP = max(MIP, [], 3);
                
                imshow(MIP, [])
                roi = drawrectangle;
                pause
                
                maskExclude = createMask(roi);
                
                %Generate output file
                [fpath, fname] = fileparts(reader.filename);
                
                imwrite(maskExclude, fullfile(fpath, [fname, '_exm.tif']), ...
                    'Compression', 'none');                

            end
            
            
        end
        
        function process(obj, files, outputDir)
            
            %Create a struct containing processing options
            opts.maskExclude = '';
            opts.channelToTrack = obj.ChannelToTrack;
            opts.thresholdLvl = obj.ThresholdLvl;
            opts.linkScoreRange = obj.LinkRange;
            opts.exportVideo = obj.ExportVideo;
            
            %Create output directory if it doesn't exist
            if ~exist(outputDir, 'dir')
                mkdir(outputDir);                
            end
            
            if ~iscellstr(files)
                files = {files};                
            end
            
            for iF = 1:numel(files)
                
                %Check if the exclusion mask exists
                [fPath, fName] = fileparts(files{iF});
                if exist(fullfile(fPath, [fName, '_exm.tif']), 'file')
                    opts.maskExclude = fullfile(fPath, [fName, '_exm.tif']);
                end
                
                fprintf([datestr(now, 'dd-mmm-yy HH:MM'), ': ', ...
                    fName, ' Processing started...\n'])
                
                CMTrack.processFile(files{iF}, outputDir, opts);
                
                fprintf([datestr(now, 'dd-mmm-yy HH:MM'), ': ', ...
                    fName, ' Processing complete\n'])
                
            end
            
        end
        
    end
    
    methods (Static)
        
        function processFile(filename, outputDir, opts)
            %PROCESSFILE  Process the specified file
            %
            %  PROCESSFILE(FILENAME, OPTS) will identify (segment) and
            %  track cells in the image specified above. Processing options
            %  must be specified in the struct OPTS.
            %
            %  OPTS must have the following fields:
            %    maskExclude - Path to exclusion mask or empty string
            %    thresholdLvl - number specifying threshold grayscale value
            %    linkScoreRange - Range of distances (in pixels) to link
            %                     objects
            %    exportVideo - Logical to create and save a video
            
            reader = BioformatsImage(filename);
            
            %Create the tracking object
            LAP = LAPLinker;
            LAP.LinkScoreRange = [0 15];
            
            [~, fName] = fileparts(reader.filename);
            
            %Create video file if selected
            if opts.exportVideo
                vidXY = VideoWriter(fullfile(outputDir, [fName, '_XY.avi']));
                vidXY.FrameRate = 5;
                open(vidXY)
                
                vidXZ = VideoWriter(fullfile(outputDir, [fName, '_XZ.avi']));
                vidXZ.FrameRate = 5;
                open(vidXZ)                
            end
            
            nObjExROI = zeros(1, reader.sizeT);
            
            for iT = 1:reader.sizeT              
                
                %Create matrices to store image and mask
                storeI = zeros(reader.height, reader.width, reader.sizeZ);
                storeMask = false(reader.height, reader.width, reader.sizeZ);
                
                storeMaskEx = false(reader.height, reader.width, reader.sizeZ);
                
                %Read in the exclusion mask if it exists
                if ~isempty(opts.maskExclude)
                    maskExclude = imread(opts.maskExclude);
                else
                    maskExclude = false(reader.height, reader.width);
                end
                
                for iZ = 1:reader.sizeZ
                    
                    %Read in z-stack images
                    storeI(:, :, iZ) = getPlane(reader, iZ, opts.channelToTrack, iT);
                    
                    %Create a mask of the bright objects
                    currMask = storeI(:, :, iZ) > opts.thresholdLvl;
                    storeMask(:, :, iZ) = currMask & ~maskExclude;
                    storeMaskEx(:, :, iZ) = currMask & maskExclude;
                    
                end
                
                %Compute the centroid positions
                data = regionprops(storeMask, 'Centroid');
                
                %Track data
                LAP = assignToTrack(LAP, iT, data);
                
                %Compute number of objects in exluded region
                dataEx = regionprops(storeMask, 'Centroid');
                nObjExROI(iT) = numel(dataEx);
                
                if opts.exportVideo
                    
                    %Make a video
                    MIPxy = max(storeI, [], 3);
                    
                    IoutXY = double(MIPxy);
                    IoutXY = IoutXY ./ max(IoutXY(:));
                    
                    IoutXY = showoverlay(IoutXY, max(storeMask, [], 3), 'Opacity', 40);
                    
                    MIPxz = max(storeI, [], 1);
                    MIPxz = squeeze(MIPxz);
                    maskxz = max(storeMask, [], 1);                    
                    maskxz = squeeze(maskxz);
                    
                    IoutXZ = double(MIPxz);
                    IoutXZ = IoutXZ ./ max(IoutXZ(:));
                    IoutXZ = showoverlay(IoutXZ, maskxz, 'Opacity', 40);
                    
                    for iTA = 1:numel(LAP.activeTrackIDs)
                        
                        ct = getTrack(LAP, LAP.activeTrackIDs(iTA));
                        
                        %Generate a random color based on the trackID
                        rng(LAP.activeTrackIDs(iTA))
                        color = rand(1, 3);
                        
                        if size(ct.Centroid, 1) > 1
                            IoutXY = insertShape(IoutXY, 'line', reshape(ct.Centroid(:, 1:2)', 1, []), ...
                                'Color', color);
                            
                            IoutXZ = insertShape(IoutXZ, 'line', reshape(ct.Centroid(:, [1 3])', 1, []), ...
                                'Color', color);                            
                        end
                    end
                    
                    IoutXY = imresize(IoutXY, 3);
                    IoutXY(IoutXY < 0) = 0;
                    IoutXY(IoutXY > 1) = 1;
                    
                    writeVideo(vidXY, IoutXY);
                    
                    IoutXZ = imresize(IoutXZ, 3);
                    IoutXZ(IoutXZ < 0) = 0;
                    IoutXZ(IoutXZ > 1) = 1;
                    
                    try
                        writeVideo(vidXZ, IoutXZ);
                    catch
                        keyboard
                    end
                    
                end
                
            end
            
            if opts.exportVideo
                close(vidXY);
                close(vidXZ);
            end
            
            trackData = LAP.tracks;
            
            %Save tracked data
            save(fullfile(outputDir, [fName, '.mat']), ...
                'trackData', 'nObjExROI');
        end
        
    end
    
    
    
end








