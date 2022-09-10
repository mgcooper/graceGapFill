% clean % alias for clear all; close all; clc;

saveData    = true;
gapFill     = true;
plotFigs    = true;    % if false, figures are not made
showFigs    = true;     % if false, figure is made but not shown
saveFigs    = false;

pathGrace   = '/path/to/GRACE/data/';
pathSave    = '/path/to/save/the/data/';

% the grace data used here is from the university of texas at austin:
% http://www2.csr.utexas.edu/grace/RL06_mascons.html

% note on resolution: '0.25 degree grid; however the mascons are estimated
% on a 1-degree equal area mascons and the native resolution of the
% GRACE/GRACE-FO data is roughly 300km'

% the calendar is gregorian, which should be correct using the datetime
% function method i use below, but not sure about time zone

load('coastlines.mat'); % useful for plotting

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% read the GRACE data
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% read the grace data:
fgrace      = 'CSR_GRACE_GRACE-FO_RL06_Mascons_all-corrections_v02.nc';
finfo       = ncinfo([pathGrace fgrace]);
Grace       = ncreaddata([pathGrace fgrace],{finfo.Variables.Name});

% georeference the data
[LAT,LON]   = meshgrat(double(Grace.lat),double(Grace.lon));
LWE         = flipud(double(Grace.lwe_thickness));
cellRes     = 1/4; % 1/4th degree
latlim      = [min(LAT(:))-cellRes/2 max(LAT(:))+cellRes/2];
lonlim      = [min(LON(:))-cellRes/2 max(LON(:))+cellRes/2];
rasterSize  = size(LWE(:,:,1));
R           = georefcells(latlim,lonlim,rasterSize,'ColumnsStartFrom','north');

% time is 'days since 2002-01-01T00:00:00Z'
T1          = datetime(2002,1,1,0,0,0);
T           = datetime(datenum(T1)+Grace.time,'ConvertFrom','datenum');

% for reference, this would also work
% T           = datetime(2002,1,1,0,0,0) + days(grace.time);

% build a bounding box around the arctic
minlat      = 40; 
minlon		= -170;
maxlat      = 85; 
maxlon 		= -48;
bbox        = [minlon,minlat;maxlon,maxlat];
xbox        = [bbox(1),bbox(2),bbox(2),bbox(1),bbox(1)];
ybox        = [bbox(3),bbox(3),bbox(4),bbox(4),bbox(3)];

% for plotting, plot the average 
LWEavg      = mean(LWE,3);
LWE0        = zeros(size(LWEavg));

% crop the grace data to the study area 
[LWEcrop,Rcrop] = geocrop(LWE,R,[minlat maxlat],[minlon maxlon]);
LWEcrop0        = zeros(size(LWEcrop,1),size(LWEcrop,2));

% use the cropped data (LWE) and lat/lon
LWE         = LWEcrop;
R           = Rcrop;
[LON,LAT]   = R2grat(R);
LON         = wrapTo180(LON);       % the basins are -180:180 so wrap grace too

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% plot it
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% plot the global data
figure(1); 
geoshow(LWE0,R,'CData',LWEavg,'DisplayType','texturemap');
hold on; geoshow(coastlat,coastlon); colormap('parula'); colorbar
set(gca,'ColorScale','log'); axis tight; 
plot(xbox,ybox,'r')


% plot the cropped data
figure(2); 
geoshow(LWEcrop0,Rcrop,'CData',mean(LWEcrop,3),'DisplayType','texturemap'); 
hold on; geoshow(coastlat,coastlon); colorbar
set(gca,'ColorScale','log'); axis tight; % plotBbox(bbox,'r');
plot(xbox,ybox,'r')


% plot with the wrapped Lon to make sure it worked
figure(3); geoshow(LAT,LON,mean(LWE,3),'DisplayType','texturemap'); 
hold on; geoshow(coastlat,coastlon); colorbar
set(gca,'ColorScale','log'); axis tight; plot(xbox,ybox,'r');

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Gap filling
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% make a calendar for the gap-filled data, for the reference period
TnoFill = T;
idx     = isbetween(TnoFill,datetime(2004,1,1),datetime(2009,12,31));
Tref    = TnoFill(idx);
Tfill   = datetime(TnoFill(1):calmonths(1):TnoFill(end)+3);

% reset the indices to be relative to the grace data
nmonths = numel(Tfill);
Tgrace  = Tfill;
idx     = isbetween(Tgrace,datetime(2004,1,1),datetime(2009,12,31));


% reshape the LWE and lat/lon to find points in each polygon
lwe     = reshape(LWE,size(LWE,1)*size(LWE,2),size(LWE,3));
lon     = reshape(LON,size(LON,1)*size(LON,2),1);
lat     = reshape(LAT,size(LAT,1)*size(LAT,2),1);
buffer  = 0;

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% example of running for one point

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% send these options to the function
opts.showFigs   = showFigs;
opts.plotFigs   = plotFigs;
opts.saveFigs   = saveFigs;
opts.pathSave   = pathSave;

% note - if showFigs is true, the function below will make a figure for
% every timeseries and pause to look at it, so you have to press any button
% to advance to the next point. If you set plotFigs true but showFigs
% false, and saveFigs true, the figures will be made and saved to look at
% later

Data = fillGRACE(TnoFill,lwe(1,:),opts);


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% This is how I ran the algorithm for a shapefile of basins - 

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% % bounds is a structure that contains polyshape objects, one for each 
% % basin, created by reading in basin shapefiles and converting the lat-
% % lon values to polyshapes. This loop finds the Grace lat/lon values 
% % within each basin+buffer, gap-fills all those points and saves the data 
% % one file per basin. see util/pointsinPoly and util/fillGRACE. 
% 
% for n = 1:nbasins
%      
%     poly        = bounds.poly(n).geo;
%     Points      = pointsInPoly(lon,lat,poly,buffer);
%     npts(n)     = sum(Points.inpoly);
%     Sa          = lwe(Points.inpoly,:);
%     
%     % NEW, gap fill at the pixel-scale - VERY SLOW, but necessary to get
%     % error / stdv estimates 
%     
%     if gapFill == true
%         fprintf('working on basin %d\n',n);
%         
%         Data = fillGRACE(TnoFill,Sa);
%         
%         % note - this saves all the 'cells' meaning the data at all the 
%         % sub-basin interpolation points
%         if saveData == true
%             Data.meta   = bounds.meta(n,:);
%             sta         = char(bounds.meta.station(n));
%             save([pathSave 'cells/grace_filled_' sta],'Data');
%         end
%         
%     end
% end
% 
% 
% 
