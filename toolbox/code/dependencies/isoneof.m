function tf = isoneof(x, menu)
   %ISONEOF Validate if x is one member of a menu.
   %
   %  tf = isoneof(x, menu)
   %
   % Use isoneof for strict input parsing with addOptional. Unlike the standard
   % method, typically @(x) any(validatestring(x, validOptions)), which permits
   % case-insensitive and partial matching, isoneof requires an exact match of
   % one argument. Note that the use of 'any' in the "typical" example above
   % works if menu is comprised of chars, even if x is a string (the match will
   % be returned as a char), but will fail if menu is a string array.

   tf = sum(ismember(x, menu)) == 1;
end
