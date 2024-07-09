# GraceGapFill

## Background

The `graceGapFill` toolbox implements the GRACE Singular Spectrum Analysis (SSA) gap-filling algorithm described in [Yi et al. (2020)](#references).

The SSA algorithm was developed and provided as Matlab code by Shuang Yi. The code provided by Shuang was refactored and packaged into this toolbox by Matt Cooper. The demo script distributed with Shuang Yi's code was refactored into a function `graceGapFill`. New code was added to create a more featured toolbox for general use. See `toolbox/code/ssa` for the core SSA algorithm code.

If you find this code useful, please cite [Shuang Yi's paper](#references). Feel free to cite this toolbox as well, if appropriate (e.g., in a "Data and Code Availability" statement, but please cite Shuang's paper for the gap-filling algorithm).

## Getting Started

Thanks for your interest. To get started, here's what we recommend:

- Clone this repo.
- Download the [GRACE data](https://www2.csr.utexas.edu/grace/RL0602_mascons.html).
- Copy the dummy example configuration file from the `demo` folder to an actual one in the top-level toolbox folder. In a terminal:
    ```sh
    cd </path/to/this/repo>/toolbox
    cp demo/config.example.m config.m
    ```
- Edit the configuration file. In a matlab terminal:
  - Type `open config.m` then press enter.
  - Replace the pathname and filename with the locations where the Grace data is saved on your computer.
  - Save and run the function.
- Open `demo/demo_GraceGapFill.m` for an example of how to use the toolbox.

## References

Shuang Yi and Nico Sneeuw _Filling the data gaps within GRACE missions using Singular Spectrum Analysis_ Journal of Geophysical Research: Solid earth https://doi.org/10.1029/2020JB021227

Cooper MG _The graceGapFill toolbox_ GitHub https://github.com/mgcooper/graceGapFill