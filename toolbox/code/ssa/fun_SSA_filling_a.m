function [X2,verror] = fun_SSA_filling_a(X,id, MM, KK)

   % mgc the missing months are assigned id == 3
   id_missing = 3;

   X2 = X;
   idx = id < 4;
   X = X(idx);
   X = X(:);

   inan = id == id_missing;

   AMP = max([nanmedian( abs(X) ), 1e-14]); % rescale the values to ~1
   X = X / AMP;

   [X_F,~,RC,htest,~,~] = ssa_missing_iterative(X, MM, KK);

   X2(inan) = X_F * AMP;

   inan = isnan(X);
   verror = std(X(~inan)-sum(RC(~inan,htest == 1),2))*AMP;
end
