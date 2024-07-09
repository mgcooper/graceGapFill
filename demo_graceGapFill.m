clearvars
close all
clc

saveDataFlag = true;
runGapFillFlag = true;
plotFiguresFlag = true; % if false, figures are not made
showFiguresFlag = true; % if false, figure is made but not shown
saveFiguresFlag = false;

pathname = getenv('GRACE_DATA_PATH');
filename = getenv('GRACE_DATA_FILE');

% For plotting
coastlat = load('coastlines.mat').('coastlat');
coastlon = load('coastlines.mat').('coastlon');

%% Data notes

% the grace data used here is from the university of texas at austin:
% http://www2.csr.utexas.edu/grace/RL06_mascons.html

% note on resolution: '0.25 degree grid; however the mascons are estimated
% on a 1-degree equal area mascons and the native resolution of the
% GRACE/GRACE-FO data is roughly 300km'

% the calendar is gregorian, which should be correct using the datetime
% function method i use below, but not sure about time zone

%% Read the GRACE data
fileinfo = ncinfo(fullfile(pathname, filename));
lat = ncread(fullfile(pathname, filename), 'lat');
lon = ncread(fullfile(pathname, filename), 'lon');
lwe = ncread(fullfile(pathname, filename), 'lwe_thickness');
time = ncread(fullfile(pathname, filename), 'time');

% time is 'days since 2002-01-01T00:00:00Z'. Convert to datetime.
time = datetime(2002,1,1,0,0,0) + days(time);

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

%% Subset the data to a bounding box

% Build a bounding box around Alaska
minlat = 40;
minlon = -170;
maxlat = 85;
maxlon = -48;
bbox = [minlon,minlat;maxlon,maxlat];
xbox = [bbox(1),bbox(2),bbox(2),bbox(1),bbox(1)];
ybox = [bbox(3),bbox(3),bbox(4),bbox(4),bbox(3)];

% Crop the grace data to a study area
[LWEcrop, Rcrop] = geocrop(LWE, R, [minlat maxlat], [minlon maxlon]);

% use the cropped data (LWE) and lat/lon
LWE = LWEcrop;
R = Rcrop;
[LON, LAT] = R2grat(R);
LON = wrapTo180(LON); % wrap grace coordinates to -180:180

%% Plot the cropped data
figure(2);
hold on
worldmap('World')
geoshow(mean(LWEcrop,3), Rcrop, 'DisplayType', 'texturemap');
plotm(coastlat, coastlon, 'k')
colorbar
set(gca, 'ColorScale', 'log')

%% Plot with the wrapped Lon to make sure it worked
figure(3)
hold on
worldmap('World')
geoshow(LAT, LON, mean(LWE,3), 'DisplayType', 'texturemap');
plotm(coastlat, coastlon, 'k')
colorbar
set(gca, 'ColorScale', 'log')



%% Gap filling

% reshape the LWE and lat/lon to find points in each polygon
lwe = reshape(LWE, size(LWE,1) * size(LWE,2), size(LWE,3));
lon = reshape(LON, size(LON,1) * size(LON,2), 1);
lat = reshape(LAT, size(LAT,1) * size(LAT,2), 1);
buffer = 0;

%% Example of running for one point

% If showFiguresFlag is true, the function below will make a figure for
% every timeseries and pause to look at it, so you have to press any button
% to advance to the next point. If you set plotFiguresFlag true but
% showFiguresFlag false, and saveFiguresFlag true, the figures will be made 
% and saved to files to look at later, but not displayed as figures.

Data = graceGapFill(Time_notFilled, lwe(1, :), ...
   "plotFiguresFlag", plotFiguresFlag, ...
   "showFiguresFlag", showFiguresFlag, ...
   "saveFiguresFlag", saveFiguresFlag);

%% Run the algorithm for a shapefile of basins

% bounds is a structure that contains polyshape objects, one for each
% basin, created by reading in basin shapefiles and converting the lat-
% lon values to polyshapes. This loop finds the Grace lat/lon values
% within each basin+buffer, gap-fills all those points and saves the data
% one file per basin. see util/pointsinPoly and util/fillGRACE.
npts = zeros(nbasins, 1);
for n = 1:nbasins

   poly = bounds.poly(n).geo;
   Points = pointsInPoly(lon, lat, poly, buffer);
   npts(n) = sum(Points.inpoly);
   Sa = lwe(Points.inpoly,:);

   % Gap fill at the pixel-scale - VERY SLOW, but necessary to get
   % error / stdv estimates

   if runGapFillFlag == true
      fprintf('working on basin %d\n', n);
      Data = fillGRACE(Time_notFilled, Sa);

      % note - this saves all the 'cells' meaning the data at all the
      % sub-basin interpolation points
      if saveDataFlag == true
         Data.meta = bounds.meta(n,:);
         sta = char(bounds.meta.station(n));
         save(fullfile(pathSave, 'cells', ['grace_filled_' sta]), 'Data');
      end
   end
end
