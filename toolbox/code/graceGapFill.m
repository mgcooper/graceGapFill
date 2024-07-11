function Data = graceGapFill(time, lwe, varargin)
   %GRACEGAPFILL Gap-fill GRACE timeseries of liquid water equivalent LWE.
   %
   %  DATA = GRACEGAPFILL(TIME, LWE)
   %
   % Inputs (see functionSignatures.json):
   %
   %  time - datetime array for GRACE data
   %  lwe - numeric array of GRACE lwe_thickness time series
   %
   %  lwe can be an array of size numPoints x numTimesteps
   %  size(lwe, 2) must match numel(time) i.e., time across the column
   %
   % These are the original notes from Shuang's script. I renamed tt1 to
   % time and made it a datetime array.
   %  tt1:      equal-spaced time
   %  X1:       rearranged S, NaN is assigned to gaps
   %  X2:       results after SSA-filling-a gaps (id = 3) are filled.
   %  verror1:  error estimation, based on fitting residuals
   %  X3:       final output, all gaps are filled
   %  verror2:  error esimation, based on the cross validation (if implemented,
   %            otherwise based on fitting residuals).
   %
   % Author: Matt Cooper matt.cooper@pnnl.gov (Based on script written by
   % Shuang Yi, shuangyi.geo@gmail.com, 05/12/2021, see reference below
   % and associated github repo)
   %
   % This function implements the GRACE gap-filling algorithm in the
   % reference below. The function is based on the script that comes with
   % the repo 'main_SSA_gap_filling.m'.
   %
   % Reference:
   % "Filling the data gaps within GRACE missions using Singular Spectrum Analysis"
   % Journal of Geophysical Research: Solid earth
   % Shuang Yi, Nico Sneeuw
   % https://doi.org/10.1029/2020JB021227
   % ---
   % Shuang Yi, shuangyi.geo@gmail.com, 05/12/2021

   % Parse inputs
   kwargs = parseinputs(time, lwe, mfilename, varargin{:});

   % Define the window sizes
   MM = 24; % Window size
   KK = 10; % Maximum number of RCs to be used
   Mlist = 24:12:96;     % optional list of window sizes to try
   Klist = [1,2:2:12];   % optional list of RCs to try

   % Create a calendar
   [~, decday] = date2doy(datenum(time));
   decyear = year(time) + decday;

   % Create an array to hold time and
   tws(:, 1) = decyear; % time in decimal years

   % Generate an initial uniform timeseries with nan-filled gaps
   yy1 = year(time(1));
   yy2 = year(time(end));
   mm1 = month(time(1));
   mm2 = month(time(end));
   % mm2 = month(time(end))+1;

   [t0, X0] = uniform_time(decyear, lwe(1,:)', [yy1, mm1, yy2, mm2]);
   numtime = numel(t0);
   numdata = size(lwe,1);

   S_error = nan(numdata, 2);
   S_input = nan(numdata, numtime); % original, w/ nan in gaps
   S_part_a = nan(numdata, numtime); % output of part a
   S_filled = nan(numdata, numtime); % output of part b
   optimal_MK = nan(numdata, 2);

   % Classify observations and gaps by id
   id = zeros(size(t0));
   inan = isnan(X0);
   id(t0<2017.5 & ~inan) = 1; % 1: GRACE
   id(t0>2017.5 & ~inan) = 2; % 2: GFO
   id(t0<2017.5 & inan) = 3;  % 3: gaps within GRACE
   id(t0>2017.5 & inan) = 4;  % 4: the 11-month gap & a gap within GFO

   % Ignore identical values of lwe, which may occur if the data was resampled
   % to a finer resolution e.g. to within a river basin, using nearest neighbor
   if kwargs.ignore_nonunique_flag
      [S0, iSa, iSb] = unique(lwe(:, 1));
      nS = numel(S0);

      numPerVal = nan(nS,1);
      for n = 1:nS
         numPerVal(n) = sum(lwe(:,1) == S0(n));
      end
   else
      S0 = lwe(:, 1);
      nS = numel(S0);
      [iSa, iSb] = deal(1:nS);
   end

   % Option to append new data to existing data saved locally, previously
   % processed by this function. Here, no need to gapfill unless the
   % new data contains gaps.
   if kwargs.append_data_flag
      Data = appendNewData(t0, time, lwe, id, kwargs);
   end

   for n = 1:nS

      tws = lwe(iSa(n), :); % grace twsa data for this point

      % Generate uniformly spaced time series
      [t_uniform, s_uniform] = uniform_time(decyear, tws, [yy1, mm1, yy2, mm2]);

      % For reference, the original hard-coded values:
      % [tt1, X1] = uniform_time(ser(:,1), ser(:,2), [2002,4,2021,6]);

      % prep for gap filling
      inan = isnan(s_uniform);
      id = zeros(size(t_uniform)); % classify observations and gaps by id

      % this shouldn't ever change within this loop but keep just in case
      id(t_uniform<2017.5 & ~inan) = 1;  % 1: GRACE
      id(t_uniform>2017.5 & ~inan) = 2;  % 2: GFO
      id(t_uniform<2017.5 & inan) = 3;   % 3: gaps within GRACE
      id(t_uniform>2017.5 & inan) = 4;   % 4: the 11-month gap & a gap within GFO

      % ------------- SSA-filling-a
      [s_part_a, s_error_a] = fun_SSA_filling_a(s_uniform, id, MM, KK);

      % ------------- SSA-filling-b
      % The following code traverses Mlist & Klist to implement the cross
      % validation to find the optimal parameter set. If both Mlist and Klist
      % consist of only one element, the value will be used directly.

      % replace numUnique with nS if not using unique points:
      fprintf( ...
         'wait for cross validation: iter = %d out of %d\n', n, nS);

      [s_part_b, s_error_b, opt_MK] = fun_SSA_filling_b(...
         t_uniform, s_part_a, Mlist, Klist);

      % make plots
      if kwargs.plot_figures_flag
         if n == 1
            if kwargs.show_figures_flag
               figure('position',[1,1,1028,303],'Visible','on');
            else
               figure('position',[1,1,1028,303],'Visible','off');
            end
         end

         plot(t_uniform, s_part_b, 'o-', 'color', [1,1,1]/2);
         hold on

         errorbar(t_uniform(id == 3), s_part_a(id == 3), ...
            ones(sum(id == 3),1)*s_error_a, 'ro', 'markerfacecolor', 'r');

         errorbar(t_uniform(id == 4), s_part_b(id == 4), ...
            ones(sum(id == 4),1)*s_error_b, 'bo', 'markerfacecolor', 'b');

         legend('Final series', 'SSA-filling-a', 'SSA-filling-b', ...
            'location', 'best');
         title(sprintf('Optimal parameter: M = %d, K = %d', optimal_MK));

         if kwargs.save_figures_flag
            filename = fullfile(...
               kwargs.pathname_outputs, ['gap_filled_' int2str(n) '.png']);
            exportgraphics(gcf, filename, 'Resolution', 300);
         end
         if kwargs.show_figures_flag
            pause
         end
         if n < nS
            clf
         end
      end

      % this assigns the unique data to the redundant data
      irepl = find(iSb == n);
      for m = 1:numel(irepl)
         S_input(irepl(m), :) = s_uniform;
         S_part_a(irepl(m), :) = s_part_a;
         S_filled(irepl(m), :) = s_part_b;
         S_error(irepl(m), 1) = s_error_a;
         S_error(irepl(m), 2) = s_error_b;
         optimal_MK(irepl(m), :) = opt_MK;
      end
   end

   % retime the gapfilled data to a monthly calendar
   T = decimalyear2datetime(t_uniform);
   T.Format = 'dd-MMM-uuuu';

   % switch nargout
   %    case 1
   %       varargout{1} = S_filled;
   %
   % end
   Data.S_filled = S_filled;
   Data.S_input = S_input;
   Data.S_part_a = S_part_a;
   Data.S_error = S_error;
   Data.time = T;
   Data.optimal_MK = optimal_MK;
   Data.id = id;
end

%%
function kwargs = parseinputs(time, lwe, mfilename, varargin)
   parser = inputParser;
   parser.FunctionName = mfilename;
   parser.addRequired('time', @isdatetime);
   parser.addRequired('lwe', @isnumeric);
   parser.addParameter('pathname_outputs', '', @ischar);
   parser.addParameter('plot_figures_flag', false, @islogical);
   parser.addParameter('save_figures_flag', false, @islogical);
   parser.addParameter('show_figures_flag', false, @islogical);
   parser.addParameter('ignore_nonunique_flag', false, @islogical);
   parser.addParameter('append_data_flag', false, @islogical);
   parser.addParameter('GraceData', struct(), @isstruct);
   parser.parse(time, lwe, varargin{:});
   kwargs = parser.Results;
end

%%
function Data = appendNewData(t0, time, lwe, id, kwargs)

   % Find the indices of the new data
   tnew = decimalyear2datetime(t0);
   tnew.Format = 'dd-MMM-uuuu';

   inew = ~isbetween(tnew, ...
      kwargs.GraceData.time(1), kwargs.GraceData.time(end));

   % If the new data contains no gaps, just append the data
   if all(id(inew) < 3)

      S_old = kwargs.GraceData.S;
      S1old = kwargs.GraceData.S1;
      S2old = kwargs.GraceData.S2;

      % need to rebuild inew relative to the calendar w/gaps
      inew = ~isbetween(time, ...
         kwargs.GraceData.time(1), kwargs.GraceData.time(end));

      % assign the old data to data and append the new data
      Data = kwargs.GraceData;
      Data.S = cat(2, S_old, lwe(:, inew));
      Data.S1 = cat(2, S1old, lwe(:, inew));
      Data.S2 = cat(2, S2old, lwe(:, inew));
      Data.time = tnew;
      Data.id = id;
   else
      % need to figure out how i want to handle this, it means the new
      % data i am appending has missing values
   end
end
