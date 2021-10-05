clearvars
clc

CM = CMTrack;

createExclusionMask(CM, 'D:\Projects\hind-lab\data\lumen_huvec_PAK_072121_03.nd2', ...
    [3, 10]);

exMask = imread('data\lumen_huvec_PAK_072121_03_1_exm.tif');
imshow(exMask)

%%
CM.LinkRange = [0 30];

process(CM, {'D:\Projects\hind-lab\data\lumen_huvec_PAK_072121_03.nd2', ...
    'D:\Projects\hind-lab\data\080621_3D_LD_Varied_Col_Comp_single_4mgmL_z_stack.nd2'}, ...
    'test');
