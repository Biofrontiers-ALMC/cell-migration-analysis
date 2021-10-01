clearvars
clc

CM = CMTrack;

createExclusionMask(CM, 'data\lumen_huvec_PAK_072121_03.nd2', ...
    [3, 10]);

exMask = imread('data\lumen_huvec_PAK_072121_03_exm.tif');
imshow(exMask)

%%

process(CM, 'data\lumen_huvec_PAK_072121_03.nd2', ...
    'test');
