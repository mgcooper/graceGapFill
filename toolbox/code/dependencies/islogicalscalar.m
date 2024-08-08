function tf = islogicalscalar(x)
   tf = islogical(x) && isscalar(x);
end
