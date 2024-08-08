function T = mkcalendar(t1,t2,dt,varargin)
   %MKCALENDAR makes a calendar
   %
   %  T = mkcalendar(t1,t2,dt)
   %  T = mkcalendar(t1,t2,dt,'noleap')
   %  T = mkcalendar(t1,t2,dt,'TimeZone','UTC')
   %  T = mkcalendar(t1,t2,dt,'noleap','TimeZone','UTC')
   %
   % See also

   % parse inputs
   [t1, t2, dt, CalType, TimeZone] = parseinputs(mfilename, t1, t2, dt, varargin{:});

   % parse the timestep if a string was passed in
   if ischar(dt)
      dt = str2duration(dt,'caltime',true);
   end

   % build a calendar
   T = tocolumn(t1:dt:t2);

   % set the time zone
   if TimeZone ~= "none"
      T.TimeZone = TimeZone;
   end

   % remove leap inds
   if CalType == "noleap"
      T = rmleapinds(T);
   end
end

%% Parse inputs
function [t1, t2, dt, CalType, TimeZone] = parseinputs( ...
      funcname, t1, t2, dt, varargin)

   parser = inputParser;
   parser.FunctionName = funcname;
   parser.CaseSensitive = false;
   parser.KeepUnmatched = true;

   validCalType = @(x) ~isempty(validatestring(x, ...
      {'noleap', 'leap'}));
   validTimeZone = @(x) ~isempty(validatestring(x, ...
      ['none', matlab.internal.datetime.functionSignatures.timezoneChoices]));

   parser.addRequired('t1', @(x)isnumeric(x)|isdatetime(x));
   parser.addRequired('t2', @(x)isnumeric(x)|isdatetime(x));
   parser.addRequired('dt', @(x)ischar(x)|isduration(x)|iscalendarduration(x));
   parser.addParameter('CalType', 'leap', validCalType);
   parser.addParameter('TimeZone', 'none', validTimeZone); % 'UTC'
   parser.parse(t1, t2, dt, varargin{:});

   t1 = parser.Results.t1;
   t2 = parser.Results.t2;
   dt = parser.Results.dt;
   CalType = parser.Results.CalType;
   TimeZone = parser.Results.TimeZone;

   if ~isdatetime(t1)
      try
         t1 = todatetime(t1);
         t2 = todatetime(t2);
      catch ME
         % let it pass
      end
   end
end
