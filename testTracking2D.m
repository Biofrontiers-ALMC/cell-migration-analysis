clearvars
clc

bfr = BioformatsImage('data\lumen_huvec_PAK_072121_03.nd2');

LAP = LAPLinker;
LAP.LinkScoreRange = [0 30];

vid = VideoWriter('lumen_huvec_PAK_072121_03.avi');
vid.FrameRate = 5;
open(vid);

for iT = 1:bfr.sizeT
    
    %Compute the MIP
    storeI = zeros(bfr.height, bfr.width, bfr.sizeZ);
    
    for iZ = 1:bfr.sizeZ
        storeI(:, :, iZ) = getPlane(bfr, iZ, 1, iT);
    end
    MIP = max(storeI, [], 3);
    
    %Generate a mask
    mask = MIP > 1800;
%     showoverlay(MIP, mask)
    
    data = regionprops(mask, 'Centroid');
    
    LAP = assignToTrack(LAP, iT, data);
    
    %Make a video
    Idbl = double(MIP);
    Idbl = Idbl ./ max(Idbl(:));
    
    Idbl = showoverlay(Idbl, mask, 'Opacity', 40);
    
    for iTA = 1:numel(LAP.activeTrackIDs)
        
        ct = getTrack(LAP, LAP.activeTrackIDs(iTA));
        
        %Generate a random color based on the trackID
        rng(LAP.activeTrackIDs(iTA))
        color = rand(1, 3);
        
        if size(ct.Centroid, 1) > 1
            Idbl = insertShape(Idbl, 'line', reshape(ct.Centroid', 1, []), ...
                'Color', color);
        end
%         Idbl = insertText(Idbl, ct.Centroid(end, :), LAP.activeTrackIDs(iTA), ...
%             'BoxOpacity', 0, 'TextColor', 'blue');    
    end
    
    Idbl = imresize(Idbl, 3);
    Idbl(Idbl < 0) = 0;
    Idbl(Idbl > 1) = 1;
    
    writeVideo(vid, Idbl);
    
%     showoverlay(storeI(:, :, 10), storeMask(:, :, 10), ...
%         'Opacity', 40);
%     
%     imshow(MIP, [])
%     keyboard
        
end

close(vid);

save('lumen_huvec_PAK_072121_03_2D.mat', 'LAP')






