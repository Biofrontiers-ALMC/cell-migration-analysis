# Cell Migration Analysis Toolbox

Welcome to the Cell Migration Analysis toolbox, a MATLAB toolbox developed in collaboration with the Hind Lab at CU Boulder.

## Installation and Usage

Download the latest [release](https://github.com/Biofrontiers-ALMC/cell-migration-analysis/releases). You only need the .mltbx (MATLAB toolbox) file. Open the file and MATLAB and it should install automatically.

### Basic usage

Create a new ``CMTrack`` object:
```matlab
CM = CMTrack;
```

If there is a region that you would like to exclude from the movie you are tracking, run the command ``createExclusionMask``. This will create a TIF file with a mask of the region to be excluded:
```matlab
createExclusionMask(CM, 'data\lumen_huvec_PAK_072121_03.nd2', [3, 1]);
```

Finally, run the method ``process``:
```matlab
process(CM, 'data\lumen_huvec_PAK_072121_03.nd2', 'outputDir');
```

### Required toolboxes
The .mltbx file should download the required toolboxes listed below. If not, download and install the latest releases of the following:
* [BioFormats MATLAB](https://github.com/Biofrontiers-ALMC/bioformats-matlab/releases)
* [Cell Tracking Toolbox](https://github.com/Biofrontiers-ALMC/cell-tracking-toolbox/releases/tag/v2.0.1)

## Contribute

### Bug reports and feature requests

Please use the [Issue Tracker](https://github.com/Biofrontiers-ALMC/cell-migration-analysis/issues) to file a bug report or to request new features.

### Development 

- The source code can be cloned from the repository
```git
git clone git@github.com:Biofrontiers-ALMC/cell-migration-analysis.git
```


