function tf = isnumericscalar(x)
   tf = isnumeric(x) && isscalar(x);
end
