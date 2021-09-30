clearvars
clc

inputFile = 'lumen_huvec_PAK_072121_03.nd2';

bfr = BioformatsImage(['data\', inputFile]);

%Select exclusion region
I = getPlane(bfr, 1, 1, 1);
imshow(I, [])
roi = drawrectangle;
pause
maskExclude = createMask(roi);

imshow(maskExclude)

return;

%%

vid = VideoWriter([inputFile(1:end - 4), '.nd2']);
vid.FrameRate = 5;
open(vid);

LAP = LAPLinker;
LAP.LinkScoreRange = [0 15];

for iT = 1:bfr.sizeT
    
    storeI = zeros(bfr.height, bfr.width, bfr.sizeZ);
    
    storeMask = false(bfr.height, bfr.width, bfr.sizeZ);
    for iZ = 1:bfr.sizeZ
        
        storeI(:, :, iZ) = getPlane(bfr, iZ, 1, iT);
        storeMask(:, :, iZ) = storeI(:, :, iZ) > 1800 & ~maskExclude;        

    end
    
    data = regionprops(storeMask, 'Centroid');
    
    LAP = assignToTrack(LAP, iT, data);    
    
    %Make a video
    MIP = max(storeI, [], 3);
    
    Idbl = double(MIP);
    Idbl = Idbl ./ max(Idbl(:));
    
    Idbl = showoverlay(Idbl, max(storeMask, [], 3), 'Opacity', 40);
    
    for iTA = 1:numel(LAP.activeTrackIDs)
        
        ct = getTrack(LAP, LAP.activeTrackIDs(iTA));
        
        %Generate a random color based on the trackID
        rng(LAP.activeTrackIDs(iTA))
        color = rand(1, 3);
        
        if size(ct.Centroid, 1) > 1
            Idbl = insertShape(Idbl, 'line', reshape(ct.Centroid(:, 1:2)', 1, []), ...
                'Color', color);
        end
        %         Idbl = insertText(Idbl, ct.Centroid(end, :), LAP.activeTrackIDs(iTA), ...
        %             'BoxOpacity', 0, 'TextColor', 'blue');
    end
    
    Idbl = imresize(Idbl, 3);
    Idbl(Idbl < 0) = 0;
    Idbl(Idbl > 1) = 1;
    
    writeVideo(vid, Idbl);
        
end

close(vid)

save([inputFile(1:end-4), '_3d.mat'], 'LAP')