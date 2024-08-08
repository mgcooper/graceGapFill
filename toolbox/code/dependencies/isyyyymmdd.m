function [tf, yyyy, mm, dd] = isyyyymmdd(t, varargin)
   %ISYYYYMMDD Check if the input is a date in the yyyyMMdd format.
   %
   % Syntax:
   %   [tf, yyyy, mm, dd] = isyyyymmdd(t)
   %
   % Description:
   %   Determines whether the provided input represents a valid date in
   %   the format yyyyMMdd. The function checks for both numeric and
   %   string inputs, converting strings to numbers where necessary.
   %
   % Inputs:
   %   t - The input date to check, provided either as a numeric scalar
   %       or a string. The format should be either yyyyMMdd (e.g., 20230101)
   %       or yyyymm (e.g., 202301).
   %
   % Outputs:
   %   tf - A logical value indicating whether 't' is a valid date in the
   %        yyyyMMdd format. Returns true for valid dates, false otherwise.
   %   yyyy - The year component of the date. Returns NaN if 't' is not a
   %          valid date.
   %   mm - The month component of the date. Returns NaN if 't' is not a
   %        valid date.
   %   dd - The day component of the date. Returns NaN if 't' is not a
   %        valid date.
   %
   % Examples:
   %   [tf, year, month, day] = isyyyymmdd('20230101');
   %   [tf, year, month, day] = isyyyymmdd(20230101);
   %
   % Notes:
   %   - The function does not support yyyymd (e.g., 202311) format.
   %   - The function does not, by default, determine if the date is valid, only
   %   if the format is consistent with yyyyMMdd. For instance, it does not
   %   account for leap years or the varying number of days in each month,
   %   meaning 20190219 will be validated as true by this function.
   %   - To require valid dates, set the optional input 'validateDate', true.
   %
   % See also: str2double, datenum

   % Allow numeric or string input
   if ischar(t) || isStringScalar(t)
      t = str2double(t);
   end
   assert(isnumeric(t), 'Expected input 1, T, to be a numeric scalar')

   % Set whether the date must be a valid date
   ValidateDate = false;
   if nargin == 3
      if strcmpi(varargin{1}, 'ValidateDate') && islogical(varargin{2})
         ValidateDate = varargin{2};
      else
         validatestring(varargin{1}, {'ValidateDate'}, mfilename)
         validateattributes(varargin{2}, {'logical'}, {'scalar'}, mfilename)
      end
   end
   % Initialize tf false and date parts nan
   tf = false;
   [yyyy, mm, dd] = deal(nan);

   % Compute the number of digits and parse the date
   numdigits = floor(log10(abs(t))) + 1 ;
   if numdigits < 6 || 8 < numdigits
      return
   else

      xStr = num2str(t);
      yyyy = str2double(xStr(1:4));
      switch numdigits
         case 6
            % This case is here to permit yyyymd format, but I was unable to
            % find a method to distinguish this case from datenums, so I
            % commented it out. Keep this for reference.
            % mm = str2double(xStr(5));
            % dd = str2double(xStr(6));
         case 8
            mm = str2double(xStr(5:6));
            dd = str2double(xStr(7:8));
         otherwise
            tf = false;
            return
      end

      if ValidateDate
         % Logic to check leap year and adjust February days
         isLeapYear = mod(yyyy, 4) == 0 ...
            & (mod(yyyy, 100) ~= 0 | mod(yyyy, 400) == 0);
         maxDaysInMonth = [31, isLeapYear * 29 + ~isLeapYear ...
            * 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      else
         maxDaysInMonth = 31 * ones(12, 1);
      end
   end

   % Validate the month and day
   if mm >= 1 && mm <= 12 && dd >= 1 && dd <= maxDaysInMonth(mm)
      tf = true;
   else
      tf = false;
      [yyyy, mm, dd] = deal(nan);
   end
end
