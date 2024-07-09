function [X4,verror,opt_MK] = fun_SSA_filling_b(tt,X, Mlist, Klist)

   % if Mlist or Klist has more than one element, a cross validation will be
   % implemented (time consuming!);
   % otherwise (e.g., Mlist = 60, Klist = 10), directly use these parameters.

   if numel(tt) ~= numel(X)
      error('The sizes of inputs are not the same');
   end

   inan = isnan(X);

   if numel(Mlist)*numel(Klist) > 1 % cross validation is required

      % mgc: GRACE period
      idx   = tt >= 2003 & tt < 2017;
      X2    = X(idx);
      tt2   = tt(idx);

      M     = Mlist;
      K     = Klist;
      numK  = numel(K);
      numM  = numel(M);

      yrs   = 2004:3:2015;

      cross_v = zeros(numK,numM);

      for  iK = 1:numK
         for iM = 1:numM

            % fprintf('M = %d\n',M(iM));
            diff_yr = zeros(numel(yrs),1);

            for iyr = 1:numel(yrs)

               ind_yr = floor(tt2) == yrs(iyr);
               % ind_compare = ind_yr & ~ind_nan;
               X3          = X2;
               X3(ind_yr)  = NaN;
               X_known     = X2(ind_yr);

               % [~,RC,htest] = ssa_yi_missing(X2, M(iM), K(iK));
               MM = M(iM);
               KK = K(iK);
               [X_F,~,RC,htest] = ssa_missing_iterative(X3, MM, KK);

               icheck = 0;
               if icheck == 1
                  b = sum(RC(:,htest==1),2);
                  plot(tt2,X2,'bo'); hold on;
                  plot(tt2,X3,'rx-');
                  plot(tt2,b,'^-'); hold off
                  axis_year(2003,2017);
                  legend('True model','input','reconstruct','location','best');
                  title(sprintf('iyr = %d, M = %d, K = %d',yrs(iyr),MM,KK));
                  pause;
               end
               % mgc I replaced function rms with rootmeansquare
               diff_yr(iyr) = rootmeansquare(X_known(:) - X_F);
            end % iyr
            cross_v(iK,iM) = rootmeansquare(diff_yr);
         end %iM
      end
      % close(f);
      verror         = min(cross_v(:));
      [iloc1,iloc2]  = find(cross_v == verror);
      iloc1          = iloc1(1); iloc2 = iloc2(1);

      [mK,mM]  = ndgrid(K,M);
      KK       = mK(iloc1,iloc2);
      MM       = mM(iloc1,iloc2);
      opt_MK   = [MM, KK];
      [X_F]    = ssa_missing_iterative(X, MM, KK);
   else
      MM       = Mlist;
      KK       = Klist;
      opt_MK   = [MM, KK];

      [X_F,~,RC,htest] = ssa_missing_iterative(X, MM, KK);

      verror   = std(X(~inan)-sum(RC(~inan,htest==1),2));
   end

   X4 = X;
   X4(inan) = X_F;

   icheck = 0;
   if icheck == 1
      figure;
      subplot(1,3,1)
      mypcolor(mK,mM,cross_v); hold on;
      plot(KK,MM,'wo','markerfacecolor','k'); hold off;
      set(gca,'xtick',K,'ytick',M);
      xlabel('Number of RCs');ylabel('Length of window');
      title(sprintf('Optimal: M=%d, K=%d, err = %.3f',...
         MM, KK, cross_v(iloc1,iloc2)));

      % -- plot sub 2{
      subplot(1,3,2:3);
      hp(1) = plot(tt,X4,'ko-','markersize',4); hold on;
      hp(2) = errorbar(tt(inan),X_F,ones(size(X_F))*verror,...
         'ro','markersize',4,'markerfacecolor','r'); hold off;
      legend(hp,'Original series','Fitting value','location','best')
      % -- plot sub 2 }
   end
end
