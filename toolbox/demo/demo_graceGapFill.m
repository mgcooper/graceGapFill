clearvars
close all
clc

%% Set paths to the grace data file.

% The grace data used here is from the university of texas at austin:
% http://www2.csr.utexas.edu/grace/RL06_mascons.html

% The data is stored on a 0.25 degree grid; however the mascons are
% estimated on 1-degree equal-area mascons and the native resolution
% of the GRACE/GRACE-FO data is roughly 300km.

% Set these and run config.m before running this demo (See the README).
config()
pathname = getenv('GRACE_DATA_PATH');
filename = getenv('GRACE_DATA_FILE');

%% Set options

% true = run the gap fill algorithm.
% false = extract the GRACE data but do not gap-fill it.
run_gapfill_flag = true;

% true = plot the GRACE timeseries and the gap-filled data.
% false = do not plot the data.
plot_figures_flag = true;

% true = show the figures (if plot_figures_flag == true)
% false = make the figures but do not show them (useful for saving figures).
show_figures_flag = true;

% true = save the figures to disk.
% false = do not save the figures to disk.
save_figures_flag = false;

% Notes:
% If show_figures_flag is true, the function graceGapFill will make a figure for
% every timeseries and pause to look at it, so you have to press any button
% to advance to the next point. If you set plot_figures_flag true but
% show_figures_flag false, and save_figures_flag true, the figures will be made
% and saved to files to look at later, but not displayed as figures.

%% Read the GRACE data
fileinfo = ncinfo(fullfile(pathname, filename));
lat = ncread(fullfile(pathname, filename), 'lat');
lon = ncread(fullfile(pathname, filename), 'lon');
lwe = ncread(fullfile(pathname, filename), 'lwe_thickness');
time = ncread(fullfile(pathname, filename), 'time');

% time is 'days since 2002-01-01T00:00:00Z'. Convert to datetime.
time = datetime(2002,1,1,0,0,0) + days(time);

% Load coastlines for plotting
coastlat = load('coastlines.mat').('coastlat');
coastlon = load('coastlines.mat').('coastlon');

%% Make calendars
[Time_notFilled, Time_referencePeriod] = makeGraceCalendar(time, ...
   "calendarType", "notfilled");

%% Georeference the data
[LON, LAT] = meshgrid(double(lon), double(lat));
LAT = flipud(LAT);
LWE = flipud(permute(double(lwe), [2 1 3]));
cellRes = 1/4; % 1/4th degree
latlim = [min(LAT(:))-cellRes/2 max(LAT(:))+cellRes/2];
lonlim = [min(LON(:))-cellRes/2 max(LON(:))+cellRes/2];
rasterSize = size(LWE(:, :, 1));
R = georefcells(latlim, lonlim, rasterSize, 'ColumnsStartFrom', 'north');

%% Plot the data
figure(1);
hold on
worldmap('world')
geoshow(mean(LWE, 3), R, 'DisplayType', 'texturemap');
plotm(coastlat, coastlon, 'k')
colormap('parula')
colorbar southoutside
set(gca, 'ColorScale', 'log')

%% Reshape the data into lists
lwe = reshape(LWE, size(LWE,1) * size(LWE,2), size(LWE,3));
lon = reshape(LON, size(LON,1) * size(LON,2), 1);
lat = reshape(LAT, size(LAT,1) * size(LAT,2), 1);

%% Example of running for one point
Data = graceGapFill(Time_notFilled, lwe(1, :), ...
   "plot_figures_flag", plot_figures_flag, ...
   "show_figures_flag", show_figures_flag, ...
   "save_figures_flag", save_figures_flag);

%% Example of running the algorithm for a polygon representing a river basin

% Find lat/lon values within the polygon. Set buffer>0 to capture more points.
poly = load('yukon.mat').('poly');
Points = pointsInPoly(lon, lat, poly, buffer=0);
numpts = sum(Points.inpoly);

% Subset the GRACE data for points inside the Yukon River Basin
lwe_Yukon = lwe(Points.inpoly, :);

% Plot the basin onto the world map and zoom in
polylat = poly.Vertices(:, 2);
polylon = poly.Vertices(:, 1);

worldmap([min(polylat) max(polylat)], [min(polylon) max(polylon)])
scatterm(lat(Points.inpoly), lon(Points.inpoly), 20, mean(lwe_Yukon, 2), 'filled')
plotm(polylat, polylon)

% Gap fill at the pixel-scale. Note, this can be very slow, but is necessary to
% get error / stdv estimates for the basin-scale storage. To improve
% performance, set the ignore_nonunique_flag true and non-unique GRACE data will
% be ignored. That is, only pixels with unique data will be gap-filled.
% Non-unique pixels occur when nearest neighbor interpolation is used to
% resample the native (300 km) or 1-degree GRACE data onto a finer grid, e.g.,
% the 0.25 x 0.25 degree grid used by the CSR data. In that case, neighboring
% pixels are often identical. The graceGapFill function only gap-fills one of
% these identical pixels, and imputes the infilled values for the others.

% If gap-filling at the pixel scale is not necessary, performance can be
% improved by averaging across pixels and then gap-filling the basin-scale LWE.

if run_gapfill_flag == true

   % Here, plot_figures_flag is set false to avoid creating a figure for every
   % pixel, but if desired, it can be set true and a unique figure will be
   % created for each pixel. Provide the pathname_outputs argument to control
   % where the figures are saved.
   Data = graceGapFill(Time_notFilled, lwe_Yukon, ...
      "ignore_nonunique_flag", true, ...
      "plot_figures_flag", false, ...
      "show_figures_flag", false, ...
      "save_figures_flag", false);

   % Add your own code to save the data if desired.
end

%% Plot the data

% Notice that lwe_filled has 243 timesteps whereas lwe_yukon (unfilled) has 210.
lwe_filled = Data.S_filled;

% Make another map to confirm the data is similar
worldmap([min(polylat) max(polylat)], [min(polylon) max(polylon)])
scatterm(lat(Points.inpoly), lon(Points.inpoly), 20, mean(lwe_filled, 2), 'filled')
plotm(polylat, polylon)

% Plot the timeseries for a specific point
point_index = 1;
show_figure = true;
plotGapFill(Data, point_index, show_figure)



