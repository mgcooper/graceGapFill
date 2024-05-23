# GraceGapFill

This toolbox implements the GRACE gap-filling algorithm described in:

"Filling the data gaps within GRACE missions using Singular Spectrum Analysis"
Journal of Geophysical Research: Solid earth
Shuang Yi, Nico Sneeuw
https://doi.org/10.1029/2020JB021227

The actual algorithm (and original code provided by Shuang Yi) is in code/SSA.

The demo script distributed with that repo was refactored into a function `graceGapFill`. New code was added to create a more featured toolbox.

## Usage

Download the [GRACE data](https://www2.csr.utexas.edu/grace/RL0602_mascons.html).

Copy the example configuration file to an actual one:

- `cp config.example.m config.m`

Edit the configuration file:

- Open `config.m` in your matlab editor and replace the pathname and filename with the locations to the Grace data on your computer.
- Save and run the script.

See `demo_GraceGapFill` for an example of how to use the code.
