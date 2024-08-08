function dt = str2duration(dt, varargin)
   % STR2DURATION convert time-format string to duration
   %
   %  dt = str2duration(dt,varargin), dt = 'y','mm','w','d','h','m','s'
   %
   % See also

   parser = inputParser();
   parser.FunctionName = mfilename();
   parser.addRequired('dt', @isscalartext);
   parser.addParameter('caltime', false, @islogicalscalar);
   parser.parse(dt, varargin{:});
   caltime = parser.Results.caltime;

   % decided to comment out the warning. if 'mm' or 'w' is requested, it
   % should be obvious or will become obvious

   switch dt
      case 'y'
         dt = years(1); if caltime == true; dt = calyears(1); end
      case 'mm'
         % no option for non-calendar month duration
         dt = calmonths(1);
         % if caltime == false; warning('dt is calendar duration'); end
      case 'w'
         % no option for non-calendar week duration
         dt = calweeks(1);
         % if caltime == false; warning('dt is calendar duration'); end
      case 'd'
         dt = days(1); if caltime == true; dt = caldays(1); end
      case 'h'
         dt = hours(1);
      case 'm'
         dt = minutes(1);
      case 's'
         dt = seconds(1);
   end
end
