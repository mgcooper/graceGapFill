function elsevalue = ifelse(condition, thenvalue, elsevalue)
   %IFELSE If else inlined.
   %
   %  elsevalue = ifelse(condition, thenvalue, elsevalue)
   %
   % See also: fifelse, iff

   arguments
      condition (1,1) logical
      thenvalue
      elsevalue
   end

   if condition
      elsevalue = thenvalue;
   end
end
