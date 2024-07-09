function h = plotGapFill(Data,showfigs)

   time    = datenum(Data.time);
   X3      = Data.S;
   X2      = Data.S2;
   verr1   = Data.Serr(1);
   verr2   = Data.Serr(2);
   id      = Data.id;
   opt_MK  = Data.optMK;

   if nargin==1; showfigs = true; end
   if showfigs == false
      h.f = figure('position',[100,300,1028,303],'Visible','off');
   else
      h.f = figure('position',[100,300,1028,303],'Visible','on');
   end

   hold on
   h.h1 = plot(time,X3,'o-','color',[1,1,1]/2);
   h.herr1 = errorbar(time(id == 3),X2 (id==3), ones(sum(id==3),1)*verr1, ...
      'ro','markerfacecolor','r');
   h.herr2 = errorbar(time(id == 4),X3 (id==4), ones(sum(id==4),1)*verr2, ...
      'bo','markerfacecolor','b');
   h.leg = legend('Final series','SSA-filling-a','SSA-filling-b', ...
      'location','best');
   title(sprintf('Optimal parameter: M=%d, K=%d',opt_MK));
   datetick
end
