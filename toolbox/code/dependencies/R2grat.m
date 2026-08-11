function [X,Y] = R2grat(R)
   %R2GRID construct graticules X and Y from spatial referencing object R
   %
   % R2GRID [X,Y] = R2grat(R) constructs 2-d grids X and Y of coordinate pairs
   % from spatial referencing object R
   %
   % Author: matt cooper (guycooper@ucla.edu)
   %
   % See also

   %% Check inputs

   % confirm mapping toolbox is installed
   assert(license('test','map_toolbox')==1, ...
      'rasterinterp requires Matlab''s Mapping Toolbox.')

   % confirm R is a cells or postings reference (planar or geographic)
   validateattributes(R, ...
      {'map.rasterref.MapCellsReference', ...
      'map.rasterref.GeographicCellsReference', ...
      'map.rasterref.MapPostingsReference', ...
      'map.rasterref.GeographicPostingsReference'}, ...
      {'scalar'}, 'R2grat', 'R', 2)

   % Postings: limits coincide with the outer sample points, so use the built-in
   % grid accessors directly (no inward half-cell adjustment).
   if isa(R, 'map.rasterref.MapPostingsReference')
      [X,Y] = worldGrid(R);
      return
   elseif isa(R, 'map.rasterref.GeographicPostingsReference')
      [Y,X] = geographicGrid(R);
      return
   end

   % determine if R is planar or geographic and call the appropriate function
   if strcmp(R.CoordinateSystemType,'planar')
      [Y,X] = mapR2grat(R);
   elseif strcmp(R.CoordinateSystemType,'geographic')
      [Y,X] = geoR2grat(R);
   end

   %% apply the appropriate function

   function [Y,X] = mapR2grat(R)

      % build query grid from R, adjusted to cell centroids
      xpsz = R.CellExtentInWorldX; % x pixel size
      xmin = R.XWorldLimits(1)+xpsz/2; % left limit
      xmax = R.XWorldLimits(2)-xpsz/2; % right limit
      xq = xmin:xpsz:xmax;

      % y direction
      ypsz = R.CellExtentInWorldY; % y pixel size
      ymin = R.YWorldLimits(1)+ypsz/2; % bottom limit
      ymax = R.YWorldLimits(2)-ypsz/2; % top limit
      yq = ymin:ypsz:ymax;

      % construct unique x,y pairs for each Zq grid centroid
      % (meshgrid(xq,yq) replaces the removed meshgrat(yq,xq) -- same result:
      % X varies across columns, Y down rows)
      [X,Y] = meshgrid(xq,yq);

      % UPDATE Jul 2019 added this basedon experience, this is the revers
      % of how it's done in rasterinterp
      if strcmp(R.ColumnsStartFrom,'north')
         Y = flipud(Y);
      end

      % flip the data left/right if oriented E-W. RowsStartFrom is the horizontal
      % direction ('west'|'east'); ColumnsStartFrom is vertical and never 'east',
      % so the old test was a dead branch.
      if strcmp(R.RowsStartFrom,'east')
         X = fliplr(X);
      end

   end

   function [Y,X] = geoR2grat(R)

      % build query grid from R, adjusted to cell centroids
      lonpsz = R.CellExtentInLongitude; % x pixel size
      lonmin = R.LongitudeLimits(1)+lonpsz/2; % left limit
      lonmax = R.LongitudeLimits(2)-lonpsz/2; % right limit
      lonq = lonmin:lonpsz:lonmax;

      % y direction
      latpsz = R.CellExtentInLatitude; % y pixel size
      latmin = R.LatitudeLimits(1)+latpsz/2; % bottom limit
      latmax = R.LatitudeLimits(2)-latpsz/2; % top limit
      latq = latmin:latpsz:latmax;

      % construct unique x,y pairs for each Zq grid centroid
      % (meshgrid(lonq,latq) replaces the removed meshgrat(latq,lonq))
      [X,Y] = meshgrid(lonq,latq);

      % UPDATE Jul 2019 added this basedon experience, this is the revers
      % of how it's done in rasterinterp
      if strcmp(R.ColumnsStartFrom,'north')
         Y = flipud(Y);
      end

      % flip the data left/right if oriented E-W. RowsStartFrom is the horizontal
      % direction ('west'|'east'); ColumnsStartFrom is vertical and never 'east',
      % so the old test was a dead branch.
      if strcmp(R.RowsStartFrom,'east')
         X = fliplr(X);
      end
   end
end
