function varargout = todatetime(T, varargin)
   %TODATETIME try to convert input T to a datetime object
   %
   %  [T, TF, DATETYPE] = TODATETIME(T) returns input T converted to datetime
   %  format, logical TF indicating if the conversion was successful, and the
   %  inferred input date type DATETYPE which is the value of the 'ConvertFrom'
   %  property passed to DATETIME(X, 'CONVERTFROM', DATETYPE). If the conversion
   %  was not successful, then DATETYPE = 'none', and T is returned unaltered.
   %
   %  [T, _] = TODATETIME(T, DATETYPE) uses the specified input DATETYPE to try
   %  the conversion.
   %
   % Example
   %
   %
   % Copyright (c) 2023, Matt Cooper, BSD 3-Clause License, github.com/mgcooper
   %
   % See also: isdatelike

   % PARSE INPUTS
   narginchk(1,2)

   % If a cell array of strings was provided, convert to string
   if iscell(T) && all(ischarlike(T))
      T = string(T);
   end

   % quick exit if a datetime was passed in
   if all(isdatetime(T))
      [varargout{1:nargout}] = dealout(T, true, 'datetime');
      return
   end

   % All available options for conversion, sorted by my subjective preference
   alltypes = {'datenum', 'yyyymmdd', 'juliandate', 'modifiedjuliandate', ...
      'posixtime', 'excel', 'excel1904', 'tt2000', 'epochtime', 'ntp', ...
      'ntfs', '.net'};

   % Try to infer the difference between a datenum and a yyyymmdd.
   try
      if isyyyymmdd(T)
         alltypes = [alltypes(2), alltypes(1), alltypes(3:end)];
      end
   catch e

   end


   % simplest input parsing
   if (nargin<2)
      menu = alltypes;
   else
      menu = validatestring( ...
         lower(varargin{1}), alltypes, mfilename, 'datetype', 2);
      menu = {menu};
   end

   % MAIN CODE
   tf = false;

   ii = 0;
   while ~tf && ii <= numel(menu)-1
      ii = ii+1;
      try
         T = datetime(T,'ConvertFrom', menu{ii});
         tf = true;
      catch e
      end
   end

   % If all of the specified options fail, try simple conversion. For instance,
   % if a cell array of date chars is passed in, conversion will fail with
   % message "Input data must be one numeric matrix when converting from a
   % different date/time representation."
   if ~tf
      try
         T = datetime(T);
         tf = true;
      catch e
      end
   end

   if ~tf
      wid = 'MATFUNCLIB:libtime:convertToDatetimeFailed';
      msg = 'unable to convert input T to datetime';
      warning(wid, msg)
   end

   % PARSE OUTPUTS
   [varargout{1:nargout}] = dealout(T, tf, ifelse(tf, menu{ii}, 'none'));

end

%% LOCAL FUNCTIONS


%% TESTS

%!test

% ## add octave tests here

%% LICENSE

% BSD 3-Clause License
%
% Copyright (c) 2023, Matt Cooper (mgcooper)
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
