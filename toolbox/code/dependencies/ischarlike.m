function tf = ischarlike(x, varargin)
   %ISCHARLIKE Compatibility wrapper for ISTEXTLIKE.
   %
   %  TF = ISCHARLIKE(X, ...) forwards to ISTEXTLIKE(X, ...).
   %
   %  The historical name ISCHARLIKE is preserved for backward compatibility,
   %  but the predicate is really about text-like containers rather than only
   %  char-like values. New code should prefer ISTEXTLIKE.
   %
   % See also ISTEXTLIKE CONTAINSONLYTEXT MUSTCONTAINONLYTEXT

   %#codegen

   tf = istextlike(x, varargin{:});
end
