function [X_F, LAMBDA, RC, htest, EOF, PC] = ssa_missing_iterative(X,MM,KK)
   %ssa_missing_iterative
   %
   %  [X_F, LAMBDA, RC, htest, EOF, PC] = ssa_missing_iterative(X,MM,KK)
   %
   % Inputs
   %  X: time series, gap filled by NaN
   %  MM: window length
   %  KK: number of RC, KK <= MM

   if nargin == 0
      fun_ex1;
      return
   end

   tol = 1e-2;

   if numel(KK) > 1
      error('K should be a single integer');
   end
   if numel(MM) > 1
      error('M should be a single integer');
   end
   if KK > MM
      error('K = %d should < MM = %d\n',KK,MM);
   end

   X = X(:);
   N = numel(X);
   N1 = N - MM + 1;

   inan = isnan(X);
   if sum(inan) > 0
      maxiter = 10000;
      iK = 1;
   else
      maxiter = 1;
      iK = KK;
   end

   X1 = zeros(size(X));
   EOF = NaN(MM, MM);
   PC = NaN(N1, MM);
   RC = NaN(N,iK);

   for iter = 1:maxiter

      % alternative to signal processing function rms
      v_diff = rootmeansquare(X(inan)-X1(inan)) / rootmeansquare(X(inan));

      % fprintf('iter = %d, K = %d: rms(diff) = %.5e\n',iter,iK,v_diff);
      X(inan) = X1(inan);

      if v_diff < tol
         if iK == KK
            break;
         else
            iK = iK+1;
         end
      end

      Y = zeros(N1,MM);
      for m = 1:MM
         Y(:,m) = X((1:N1) + m-1);
      end

      [U,S,V] = svd(Y);
      LAMBDA = diag(S.^2);
      EOF = V;
      PC = U*S;

      RC = calculateReconstructedComponents(N, N1, iK, PC, EOF);
      X1 = sum(RC(:,1:iK),2);
   end
   X_F = X1(inan);

   % htest is 'CDF test' in Figure 2
   htest(KK) = 0;
   for ii = 1:KK

      % alternative to signal processing toolbox function
      b = powerSpectralDensity(EOF(:,ii));
      % https://www.mathworks.com/help/signal/ug/power-spectral-density-estimates-using-fft.html

      % reactivate this to use periodogram
      % [b,~] = periodogram( EOF(:,ii) );

      cum_pdf = cumsum(b) / max(cumsum(b));
      htest(ii) = cum_pdf(round(length(b) / 2)) > 0.9;
   end
end

function RC = calculateReconstructedComponents(N, N1, iK, PC, EOF)
   RC = zeros(N,iK);
   for m = 1:iK

      % Invert projection
      buf = PC(:,m) * EOF(:,m)';
      buf = flipud(buf);

      % Calculate the mean of each diagonal
      for n = 1:N
         RC(n,m) = mean( diag(buf, -N1+n) );
      end
   end
end

function fun_ex1()

   M = 40; % window length = embedding dimension
   K = 10;

   % Create time series X
   % First of all, we generate a time series, a sine function of length N
   % with observational white noise

   % rng('default');

   vCS2 = load('csr06_n20M40K20_200204-202008_ssa-filling-a.mat').('vCS2');
   X = vCS2(1,:);
   t = 1:numel(X);

   inan = isnan(X);

   [X_F, lambda, RC, htest ] = ssa_missing_iterative(X, M, K);

   % figure;
   subplot(2,2,1)
   a = lambda(1:min([20,numel(lambda)])); a = a/sum(a);
   x = 1:numel(a);

   yyaxis left
   plot(x, a, 'o-');

   yyaxis right
   plot(x, cumsum(a), 'o-');
   title('eigenvalues LAMBDA');

   subplot(2,2,2)
   for ii = 1:K
      plot(t,RC(:,ii));
      hold on
   end
   hold off
   legend
   title('RC')

   subplot(2,2,3)
   plot(t,X,'o-','color',[1,1,1]*0.6);
   hold on;
   plot(t,sum(RC(:,htest(1:K) == 1),2),'k-');
   plot(t(inan),X_F,'rx');

   legend('Original time series','Reconstruction with RCs','Filled value');
   hold off
end
