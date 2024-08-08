function tf = isoneof(x, menu)
   %ISONEOF Validate if x is one member of a menu.
   %
   %  tf = isoneof(x, menu)
   %
   % Use isoneof for strict input parsing with addOptional. Unlike the standard
   % method, typically @(x) any(validatestring(x, validOptions)), which permits
   % case-insensitive and partial matching, isoneof requires an exact match of
   % one argument.

   tf = sum(ismember(x, menu)) == 1;
end
