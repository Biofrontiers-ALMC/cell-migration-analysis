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

## Contribute

### Bug reports and feature requests

Please use the [Issue Tracker](https://biof-git.colorado.edu/cameron-lab/cyanobacteria-toolbox/issues) to file a bug report or to request new features.

### Development 

- The source code can be cloned from the repository
```git
git clone git@biof-git.colorado.edu:cameron-lab/cyanobacteria-toolbox.git
```
- Read the [Contributer Guide](https://biof-git.colorado.edu/cameron-lab/cyanobacteria-toolbox/wikis/home)
- The directory of the Git repository is arranged according to the best practices described in [this MathWorks blog post](https://blogs.mathworks.com/developer/2017/01/13/matlab-toolbox-best-practices/).

