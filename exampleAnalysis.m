clearvars
clc

%load('lumen_huvec_PAK_072121_03_3D.mat')
load('080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack_3d.mat');

%%
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
    
    alpha = acos(dot(u, [1 0 0 ])/magU) * sign(u(1));
    beta = acos(dot(u, [0 1 0 ])/magU) * sign(u(2));
    gamma = acos(dot(u, [0 0 1 ])/magU) * sign(u(3));
    
    directionality(iTrack, :) = [alpha, beta, gamma];
    displacementVec(iTrack, :) = currTrack.Centroid(end, :) - currTrack.Centroid(1, :);

end

%% Histogram
subplot(1, 3, 1)
polarhistogram(wrapTo2Pi(directionality(:, 1)), 20)
title('080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack (x)', 'Interpreter' ,'none')

subplot(1, 3, 2)
polarhistogram(wrapTo2Pi(directionality(:, 2)), 20)
title('080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack (y)', 'Interpreter' ,'none')

subplot(1, 3, 3)
polarhistogram(wrapTo2Pi(directionality(:, 3)), 20)
title('080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack (z)', 'Interpreter' ,'none')

%%



