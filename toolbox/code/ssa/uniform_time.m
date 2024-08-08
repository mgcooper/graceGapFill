function [t_uniform, s_uniform] = uniform_time(t0, s0, trange)
   % uniform time for SSA

   % {{SSA; time; uniform; LLZ; regulate}}

   PAR = struct('average',1,'interp',0,'gap',1/12);
   % PAR = var_initial(PAR0,varargin);
   % average=0, only search the nearest within gap/2
   % average=0, average the near month within gpa/2
   % interp=1, interpolate the missing months

   if nargin < 3
      trange = [2002,4,2019,10];
   end

   t_uniform = generate_tt(trange(1:2), trange(3:4));
   s_uniform = nan(size(t_uniform));

   for n = 1:numel(s_uniform)
      dd = t0 - t_uniform(n);

      if PAR.average == 0
         [mindd, loc] = min(abs(dd));
         if mindd <= PAR.gap/2
            s_uniform(n) = s0(loc);
         end
      else
         ind = dd<PAR.gap/2 & dd>=-PAR.gap/2;
         s_uniform(n) = mean(s0(ind));
      end
   end

   if PAR.interp == 1 % linear
      ind = ~isnan(s_uniform);
      s_uniform = interp1(t_uniform(ind), s_uniform(ind), t_uniform);
   elseif PAR.interp == 2 % SSA
      error('Option 2 is not supported') % ssa_missing_GO is missing
      % [~, RC, htest] = ssa_missing_GO(s_uniform, 48, 10);
      % s_uniform = sum(RC(:,htest==1),2);
   end

end

function [tt, sfilename] = generate_tt(t1,o_t2,idatenum)
   % {{time}} {{create}} {{str}}
   % t1 : start time, [year,month]
   % t2 : end time
   % input is ([y1,m1], [y2,m2]) or ([y1,m1, y2,m2]);

   if nargin == 1
      if numel(t1) == 4
         o_t2 = t1(3:4);
      else
         o_t2 = t1;
      end
   end

   if nargin < 3
      idatenum = 0;
   end

   if numel(t1) == 1
      t1 = time_transfer(t1,3);
      o_t2 = time_transfer(o_t2,3);
   end


   iyear1 = t1(1);
   iyear2 = o_t2(1);
   imonth1 = t1(2);
   imonth2 = o_t2(2);

   % Ntt = (iyear2-iyear1)*12 - imonth1 + imonth2 +1;
   NN = (iyear2-iyear1+1)*12;
   rtmp(1:NN,1) = 0;

   ik = 0;
   for iyear = iyear1:iyear2
      for imonth = 1:12
         ik = ik+1;
         rtmp(ik) = (imonth-0.5)/12 + iyear;% - iyear1;
      end
   end

   tt = rtmp(imonth1:end-12+imonth2);

   if idatenum == 1
      tt = time_transfer(tt(:),-1);
   end

   % ============================================================
   ik = 0;
   for iyear = iyear1:iyear2
      for imonth = 1:12
         ik = ik+1;
         stmp{ik} = sprintf('%6.6d',iyear*100 + imonth);
      end
   end
   % stmp{1:2}
   sfilename = stmp(imonth1:end-12+imonth2);
end

function t = time_transfer(t, dim)
   % mgc: this is a dummy function created to suppress code issues b/c
   % time_transfer is not in the toolbox. It is only called when numel(t1) == 1
   % or idatenum == 1, but idatenum only == 1 if its passed in to generate_tt as
   % the third arg, and the only call to generate_tt only uses 2 inputs.

   error('time_transfer function is missing')
end
