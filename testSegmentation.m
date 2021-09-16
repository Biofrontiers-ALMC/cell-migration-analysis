clearvars
clc

inputFile = '080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack.nd2';

bfr = BioformatsImage(['data\', inputFile]);

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
        storeMask(:, :, iZ) = storeI(:, :, iZ) > 1800;

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

%% Example analysis
clearvars
clc

%load('lumen_huvec_PAK_072121_03_3D.mat')
load('080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack_3d.mat');
timeBetweenFrames = 10 * 60; %Seconds

%Initialize matrices for calculations
instSpeed = cell(1, LAP.NumTracks); %Instantaneous speed
directionality = zeros(LAP.NumTracks, 3);
displacementVec = zeros(LAP.NumTracks, 3);

for iTrack = 1:LAP.NumTracks
    
    %Get current track
    currTrack = getTrack(LAP, iTrack);
    
    %Compute instantaneous speed
    instSpeed{iTrack} = sum((diff(currTrack.Centroid, 1)).^2, 2);
    
    %Compute final direction (based on start and end positions) In 3D, the
    %directionality is given by 3 angles, representing the angles between
    %the three cartesian coordinates. Each angle is given by u dot i where
    %i is the unit vector specifying the cartesian coordinate.
    u = currTrack.Centroid(1, :) - currTrack.Centroid(end, :);
    magU = norm(u);
    
    alpha = acosd(dot(u, [1 0 0 ])/magU);
    beta = acosd(dot(u, [0 1 0 ])/magU);
    gamma = acos(dot(u, [0 0 1 ])/magU) * sign(u(3));
    
    directionality(iTrack, :) = [alpha, beta, gamma];
    displacementVec(iTrack, :) = currTrack.Centroid(end, :) - currTrack.Centroid(1, :);

end

%% Histogram
polarhistogram(directionality(:, 3), 20)



%%

%Try a quiver plot
startVec = zeros(LAP.NumTracks, 3);
endVec = zeros(LAP.NumTracks, 3);

for iTrack = 1:LAP.NumTracks
    
    %Get current track
    currTrack = getTrack(LAP, iTrack);
    
    startVec(iTrack, :) = currTrack.Centroid(1, :);
    endVec(iTrack, :) = currTrack.Centroid(end, :);
    
end

dd = endVec(:, 1:2) - startVec(:, 1:2);
[X, Y] = meshgrid(-10:10, -10:10);

quiver(X, Y, dd(:, 1), dd(:, 2))




