function TF = none(X, varargin)
   %NONE Determine whether all elements of logical array X are false
   %
   %  TF = none(X)
   %  TF = none(X, 'all')
   %  TF = none(X, dim)
   %  TF = none(X, vecdim)
   %
   % Description
   %  TF = NONE(X) returns true if ~any(X) is true, false if any(X) is false
   %
   % Matt Cooper, 30-Jan-2023, https://github.com/mgcooper
   %
   % See also any, isempty, notempty, notall

   TF = ~any(X, varargin{:});
end
