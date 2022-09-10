function Data = graceGapFill(time,S,varargin)
%graceGapFill

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p = MipInputParser;
   p.FunctionName = 'graceGapFill';
   p.addRequired('time',@(x)isdatetime(x));
   p.addRequired('S',@(x)isnumeric(x));
   p.addParameter('plotfigs',false,@(x)islogical(x));
   p.addParameter('savefigs',false,@(x)islogical(x));
   p.addParameter('showfigs',false,@(x)islogical(x));
   p.addParameter('pathsave','',@(x)ischar(x));
   p.addParameter('adddata',false,@(x)islogical(x));
   p.addParameter('olddata',struct(),@(x)isstruct(x));
   p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
   
   % INPUTS (see functionSignatures.json)
   %   time    = datetime array for GRACE data
   %   S       = numeric array of GRACE time series
   
   %   S can be an array of size numPoints x numTimesteps
   %   size(S,2) must match numel(time) i.e., time across the column
   
   % these are the original notes from Shuang's script. I renamed tt1 to
   % time and made it a datetime array. 
   % tt1:      equal-spaced time
   % X1:       rearranged S, NaN is assigned to gaps
   % X2:       results after SSA-filling-a gaps (id = 3) are filled.
   % verror1:  error estimation, based on fitting residuals
   % X3:       final output, all gaps are filled
   % verror2:  error esimation, based on the cross validation (if implemented,
   %           otherwise based on fitting residuals).
   
   % Author: Matt Cooper matt.cooper@pnnl.gov (Based on script written by
   % Shuang Yi, shuangyi.geo@gmail.com, 05/12/2021, see reference below
   % and associated github repo)
   
   % This function implements the GRACE gap-filling algorithm in the
   % reference below. The function is based on the script that comes with
   % the repo 'main_SSA_gap_filling.m'.
   
   % Reference:
   % "Filling the data gaps within GRACE missions using Singular Spectrum Analysis"
   % Journal of Geophysical Research: Solid earth
   % Shuang Yi, Nico Sneeuw
   % https://doi.org/10.1029/2020JB021227
   % ---
   % Shuang Yi, shuangyi.geo@gmail.com, 05/12/2021
   
   % mgc: these shouldn't change if the input data size changes (e.g. if i
   % want to update with a new grace timeseries or other timeseries with a
   % different number of elements than the example timeseries which had 231
   % filled valeus and (I think) 206 original
   MM      = 24;           % Window size
   KK      = 10;           % Maximum number of RCs to be used
   Mlist   = 24:12:96;     % optional list of window sizes to try
   Klist   = [1,2:2:12];   % optional list of RCs to try
   
   
   [~,decday]  = date2doy(datenum(time));
   decyear     = year(time) + decday;
   
   ser(:,1)    = decyear;  % time in decimal years
   
   % use the unique values for major improvement in runtime. This could be
   % applicable if the raw Grace data were first interpolated to a set of
   % points, e.g. a basin shapefile, or some other geospatial data, at a
   % different resolution, and you end up with multiple points with
   % identical data, b/c you used nearest neighbor resampling. Or, maybe
   % the grace data you are using has redundant data, for the same reason
   % as above, b/c the Grace data is itself an interpolated product. This
   % step runs the slow algorithm over the unique data points and then
   % substitutes the solutions into the matching points that weren't run.
   [S0,iSa,iSb] = unique(S(:,1));
   
   numUnique   = numel(S0);
   numPerVal   = nan(numUnique,1);
   for n = 1:numUnique
      numPerVal(n) = sum(S(:,1)==S0(n));
   end
   
   % mgc generate an initial uniform timeseries with nan-filled gaps to
   % preallocate stuff and bypass the gap filling if requested
   % (previously they were hard coded to 231)
   yy1      = year(time(1));
   yy2      = year(time(end));
   mm1      = month(time(1));
   mm2      = month(time(end)); 
  %mm2      = month(time(end))+1;

   % mgc NOTE: I am not sure why I had mm2+1, but the consequence is that
   % t0 (and tt1 in the loop) have one month extra beyond the last month of
   % data. Maybe I wanted this to extrapolate to the end of the water year
   % or calendar year, not sure. But for the adddata check, we need to know
   % if there are any missing values otherwise skip the gapfill
   
   [t0,X0]  = uniform_time(ser(:,1),S(1,:)', [yy1,mm1,yy2,mm2]);
   nT       = numel(t0);
   nS       = size(S,1);
   verr     = nan(nS,2);
   S1       = nan(nS,nT);     % original, w/ nan in gaps
   S2       = nan(nS,nT);     % output of part a
   Sfilled  = nan(nS,nT);     % output of part b
   id       = zeros(size(t0)); % classify observations and gaps by id   
   inan     = isnan(X0);
   
   % test - this should not change within the loop over points
   id(t0<2017.5 & ~inan)   = 1; % 1: GRACE
   id(t0>2017.5 & ~inan)   = 2; % 2: GFO
   id(t0<2017.5 & inan)    = 3; % 3: gaps within GRACE
   id(t0>2017.5 & inan)    = 4; % 4: the 11-month gap & a gap within GFO
      
   % if we are just appending new data, we don't need to gapfill unless the
   % new data contains gaps. first find the overlapping period
   if adddata == true
      
      % find the indices of the new data
      tnew        = decimalyear2datetime(t0);
      tnew.Format = 'dd-MMM-uuuu';
      
      inew  = ~isbetween(tnew,olddata.time(1),olddata.time(end));
      
      % if the new data contains no gaps, just append the data
      if all(id(inew)<3)
      
         Sold  = olddata.S;
         S1old = olddata.S1;
         S2old = olddata.S2;
         
         % need to rebuild inew relative to the calendar w/gaps
         inew  = ~isbetween(time,olddata.time(1),olddata.time(end));
         
         % assign the old data to data and append the new data
         Data        = olddata;
         Data.S      = cat(2,Sold,S(:,inew));
         Data.S1     = cat(2,S1old,S(:,inew));
         Data.S2     = cat(2,S2old,S(:,inew));
         Data.time   = tnew;
         Data.id     = id;
         
         return
         
      else
         % need to figure out how i want to handle this, it means the new
         % data i am appending has missing values
      end
         
   end
   
 % for n = 1:nS
   for n = 1:numUnique % mgc only gap-fill the unique values
      
      % if using 1:nS then use this:
      %ser(:,2)    = S(n,:);   % grace twsa, I am guessing
      
      % if using 1:numUnique then use this:
      ser(:,2)    = S(iSa(n),:);   % grace twsa data for this point
      
      % generate uniformly spaced time series
      [tt1,X1]    = uniform_time(ser(:,1),ser(:,2), [yy1,mm1,yy2,mm2]);
      
      % for reference, the original hard-coded values:
      % [tt1,X1]  = uniform_time(ser(:,1),ser(:,2), [2002,4,2021,6]);
      
      % prep for gap filling
      inan        = isnan(X1);
      id          = zeros(size(tt1)); % classify observations and gaps by id
      
      % this shouldn't ever change within this loop but keep just in case
      id(tt1<2017.5 & ~inan)   = 1; % 1: GRACE
      id(tt1>2017.5 & ~inan)   = 2; % 2: GFO
      id(tt1<2017.5 & inan)    = 3; % 3: gaps within GRACE
      id(tt1>2017.5 & inan)    = 4; % 4: the 11-month gap & a gap within GFO
      
      
      %~~~~~~~~~~~~~~~~~~~~~~
      %   SSA-filling-a
      %~~~~~~~~~~~~~~~~~~~~~~
      
      [X2,verror1] = fun_SSA_filling_a(X1,id, MM, KK);
      
      %~~~~~~~~~~~~~~~~~~~~~~
      %   SSA-filling-b
      %~~~~~~~~~~~~~~~~~~~~~~
      
      % The following code traverses Mlist & Klist to implement the cross
      % validation to find the optimal parameter set. If both Mlist and Klist
      % consist of only one element, the value will be used directly.
      
      % replace numUnique with nS if not using unique points:
      fprintf('wait for cross validation: iter = %d out of %d\n',n,numUnique);
      
      [X3,verror2,opt_MK] = fun_SSA_filling_b(tt1,X2,Mlist,Klist);
      
      %~~~~~~~~~~~~~~~~~~~~~~
      %   plot
      %~~~~~~~~~~~~~~~~~~~~~~
      if plotfigs == true
         if n == 1
            if showfigs == true
               figure('position',[1,1,1028,303],'Visible','on');
            else
               figure('position',[1,1,1028,303],'Visible','off');
            end
         end
         
         plot(tt1,X3,'o-','color',[1,1,1]/2); hold on;
         errorbar(tt1(id==3),X2(id==3),ones(sum(id==3),1)*verror1,   ...
            'ro','markerfacecolor','r');
         errorbar(tt1(id==4),X3(id==4),ones(sum(id==4),1)*verror2,   ...
            'bo','markerfacecolor','b');
         legend('Final series','SSA-filling-a','SSA-filling-b','location','best');
         title(sprintf('Optimal parameter: M=%d, K=%d',opt_MK));
         
         if savefigs == true
            fsavefig = [pathsave 'gap_filled_' int2str(n) '.png'];
            exportgraphics(gcf,fsavefig,'Resolution',300);
         end
         
         if showfigs == true; pause; end;
         
         if n<numUnique; clf; end;
         
      end
      
      % this assigns the unique data to the redundant data
      idx_n = find(iSb==n);
      for m = 1:numel(idx_n)
         S1(idx_n(m),:)         = X1;
         S2(idx_n(m),:)         = X2;
         Sfilled(idx_n(m),:)    = X3;
         verr(idx_n(m),1)       = verror1;
         verr(idx_n(m),2)       = verror2;
         optMK(idx_n(m),:)      = opt_MK;
      end
      
   end
   
   % retime the gapfilled data to a monthly calendar
   T           = decimalyear2datetime(tt1);
   T.Format    = 'dd-MMM-uuuu';
   
   Data.S      = Sfilled;
   Data.S1     = S1;
   Data.S2     = S2;
   Data.Serr   = verr;
   Data.time   = T;
   Data.optMK  = optMK;
   Data.id     = id;
end
