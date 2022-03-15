function Points = pointsInPoly(x,y,poly,buffer)
    %POINTSINPOLY extracts x,y points that are within poly + buffer

%     Author: matt cooper (matt.cooper@pnnl.gov)
    
% % For reference, what this is doing:
%     box     =   polyshape(lonbox,latbox);
%     in      =   inpolygon(lon,lat,lonbox,latbox);
%     varin   =   var(in);
%     latin   =   lat(in);
%     lonin   =   lon(in);

% % then findInterpolationPoints resamples latin/lonin to high-resolution
%   and clips the points to the polygon. 

    if nargin<4
        buffer  =   0;
    end
    
% feb 2022, new method buffers the bounding box, much faster for complex
% catchment polgyons with many vertices which are very slow with polybuffer
    [xb,yb] =   boundingbox(poly);
    xrect   =   [xb(1) xb(2) xb(2) xb(1) xb(1)];
    yrect   =   [yb(1) yb(1) yb(2) yb(2) yb(1)];
    polybb  =   polyshape(xrect,yrect);

    % figure; plot(poly); hold on; plot(xrect,yrect);
    
    polyb   =   polybuffer(polybb,buffer);
    xp      =   poly.Vertices(:,1);
    yp      =   poly.Vertices(:,2);
    xpb     =   polyb.Vertices(:,1);
    ypb     =   polyb.Vertices(:,2);
    inp     =   inpolygon(x,y,xp,yp);
    inpb    =   inpolygon(x,y,xpb,ypb);
    
    % assign output
    Points.inpoly     = inp;
    Points.inpolyb    = inpb;
    Points.poly       = poly;
    Points.polyb      = polyb;
    Points.xpoly      = xp;
    Points.ypoly      = yp;
    Points.xpolyb     = xpb;
    Points.ypolyb     = ypb;
    
end

