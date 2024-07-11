function y = rootmeansquare(x, dim)
   %ROOTMEANSQUARE Root mean squared value.
   %
   %   For vectors, ROOTMEANSQUARE(X) is the root mean squared value in X. For
   %   matrices, ROOTMEANSQUARE(X) is a row vector containing the RMS value
   %   from each column. For N-D arrays, ROOTMEANSQUARE(X) operates along the
   %   first non-singleton dimension.
   %
   %   Y = ROOTMEANSQUARE(X,DIM) operates along the dimension DIM.
   %
   %   When X is complex, the RMS is computed using the magnitude
   %   ROOTMEANSQUARE(ABS(X)).
   %
   %   % Example 1: RMS of sinusoid vector
   %   x = cos(2*pi*(1:100)/100);
   %   y = rms(x)
   %
   %   % Example 2: RMS of columns of matrix
   %   x = [rand(100000,1) randn(100000,1)];
   %   y = rms(x, 1)
   %
   %   % Example 3: RMS of rows of matrix
   %   x = [2 -2 2; 3 3 -3];
   %   y = rms(x, 2)
   %
   % See also:

   if isreal(x)
      if nargin==1
         y = sqrt(mean(x .* x));
      else
         y = sqrt(mean(x .* x, dim));
      end
   else
      % The way we compute mag square yields better performance than calling abs.
      if nargin==1
         y = sqrt(mean(real(x) .* real(x) + imag(x) .* imag(x)));
      else
         y = sqrt(mean(real(x) .* real(x) + imag(x) .* imag(x), dim));
      end
   end
end
