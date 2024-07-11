function Points = pointsInPoly(x, y, poly, varargin)
   %POINTSINPOLY Find x,y points within polygon plus an optional buffer
   %
   %  POINTS = POINTSINPOLY(X, Y, POLY)
   %  POINTS = POINTSINPOLY(X, Y, POLY, BUFFER=BUFFER)
   %  POINTS = POINTSINPOLY(X, Y, POLY, XBUFFER=XBUFFER, YBUFFER=YBUFFER)
   %  POINTS = POINTSINPOLY(X, Y, POLY, MAKEPLOT=TRUE)
   %  POINTS = POINTSINPOLY(X, Y, POLY, BUFFERBOX=FALSE)
   %
   % Description
   %  POINTS = POINTSINPOLY(X,Y,POLY) returns struct POINTS containing X,Y
   %  coordinates found in POLY.
   %
   % Use POINTSINPOLY to find all X,Y points within the boundaries of POLY with
   % an optional BUFFER. See interpolationPoints for an example of how these are
   % used to resample the found points to a high-resolution grid clipped to POLY
   % for use as interpolation query points. The main feature of pointsInPoly is
   % the ability to use the provided POLY or optionally generate a bounding box
   % around POLY with an optional buffer to capture sufficient grid points for
   % interpolation without extrapolation.
   %
   % Basic algorithm:
   %     box = polyshape(lonbox,latbox);
   %     in = inpolygon(lon,lat,lonbox,latbox);
   %     varin = var(in);
   %     latin = lat(in);
   %     lonin = lon(in);
   %
   % Author: matt cooper (matt.cooper@pnnl.gov)
   %
   % See also interpolationPoints, resamplingCoords

   % parse inputs
   persistent parser
   if isempty(parser)
      parser = inputParser;
      parser.FunctionName = mfilename;
      addRequired(parser, 'x', @isnumeric);
      addRequired(parser, 'y', @isnumeric);
      addRequired(parser, 'poly', @(x) isa(x, 'polyshape'));
      addParameter(parser,'buffer', nan, @isnumeric);
      addParameter(parser,'xbuffer', nan, @isnumeric);
      addParameter(parser,'ybuffer', nan, @isnumeric);
      addParameter(parser,'makeplot', false, @islogical);
      addParameter(parser,'bufferbox', true, @islogical);
      %addParameter(p,'pointinterp',false);
   end
   parse(parser,x,y,poly,varargin{:});

   buffer = parser.Results.buffer;
   xbuffer = parser.Results.xbuffer;
   ybuffer = parser.Results.ybuffer;
   makeplot = parser.Results.makeplot;
   bufferbox = parser.Results.bufferbox;

   % Note: buffering the bounding box is much faster for complex polgyons with
   % many vertices which are very slow with polybuffer.

   dobuffer = false;

   % first determine if any buffering is requested
   if (notnan(buffer) && buffer ~= 0) || notnan(xbuffer) || notnan(ybuffer)

      dobuffer = true;

      % check for x/y buffer and issue errors if incombatible with other options
      if (isnan(xbuffer) && notnan(ybuffer)) || (notnan(xbuffer) && isnan(ybuffer))
         error(['both xbuffer and ybuffer are required if either are specified. ' ...
            newline ' use default option ''buffer'' for constant buffer distance'])
      end

      % if x/ybuffer is requested, only bufferbox is supported
      if notnan(xbuffer) && bufferbox == false
         error('x/y buffer option only supported for option ''bufferbox''')
      end
   end

   % The bufferbox logic is:
   %  if bufferbox is requested, make a bounding box
   %     if x/y buffer is requested, extend the box in the x-y direction
   %        in this case, set buffer to zero, the box is now buffered
   %     if not, use the value of buffer to buffer the box
   %  ifnot, buffer the poly

   % deal with the buffer box
   if dobuffer == true && bufferbox == true

      [xb, yb] = boundingbox(poly);

      % if x/ybuffer is requested, buffer the bbox in the x-y directions
      if notnan(xbuffer)
         xb = [xb(1)-xbuffer xb(2)+xbuffer];
         yb = [yb(1)-ybuffer yb(2)+ybuffer];
         buffer = 0;
      end
      % Set buffer to zero b/c x/ybuffer was already applied. Use xrect/yrect
      % and call polyshape for the x/ybuffer and buffer cases.

      % convert the bbox to a polyshape
      xrect = [xb(1) xb(2) xb(2) xb(1) xb(1)];
      yrect = [yb(1) yb(1) yb(2) yb(2) yb(1)];

      % buffer the box
      polyb = polybuffer(polyshape(xrect,yrect), buffer);

   elseif dobuffer == true && bufferbox == false

      % buffer the provided polyshape
      polyb = polybuffer(poly, buffer);
   end

   % figure; plot(poly); hold on; plot(xrect,yrect);

   % find the points in the poly
   xp = poly.Vertices(:,1);
   yp = poly.Vertices(:,2);
   inp = inpolygon(x,y,xp,yp);

   % assign output
   Points.poly = poly;
   Points.xpoly = xp;
   Points.ypoly = yp;
   Points.inpoly = inp;

   % find the points in the poly + buffer
   if dobuffer == true

      xpb = polyb.Vertices(:,1);
      ypb = polyb.Vertices(:,2);
      inpb = inpolygon(x,y,xpb,ypb);

      % assign output
      Points.polyb = polyb;
      Points.xpolyb = xpb;
      Points.ypolyb = ypb;
      Points.inpolyb = inpb;
   else

      % assign inpoly to inpolyb consistent syntax outside the function i.e.
      % for no buffer, inpolyb = inpoly, but outside the function we can
      % always use inpolyb
      Points.polyb = poly;
      Points.xpolyb = xp;
      Points.ypolyb = yp;
      Points.inpolyb = inp;
   end

   if makeplot == true
      figure;
      if dobuffer == true
         plot(polyb); hold on; plot(poly);
      else
         plot(poly); hold on;
      end

      if dobuffer == true
         scatter(x(inpb),y(inpb),'filled');
         scatter(x(inp),y(inp),'filled');
         legend('buffer','poly','in buffer','in poly',...
            'numcolumns',4,'location','northoutside');
      else
         scatter(x(inp),y(inp),'filled');
         legend('poly','in poly',...
            'numcolumns',2,'location','northoutside');
      end
   end
end
