function varargout = plotGapFill(Data, idx, showfigs)

   if nargin < 2
      idx = 1;
   end
   if nargin < 3
      showfigs = true;
   end

   % Extract the data
   time = datenum(Data.time);
   S_input = Data.S_input(idx, :);
   S_part_a = Data.S_part_a(idx, :);
   S_filled = Data.S_filled(idx, :);
   S_error_a = Data.S_error(idx, 1);
   S_error_b = Data.S_error(idx, 2);
   time_id = Data.id;
   opt_MK = Data.optimal_MK(idx, :);

   if showfigs == false
      h.f = figure('position',[100,300,1028,303],'Visible','off');
   else
      h.f = figure('position',[100,300,1028,303],'Visible','on');
   end

   hold on
   h.errorbar_final_series = plot(time, S_filled, 'o-', 'color', [1,1,1]/2);

   h.errorbar_part_a = errorbar(time(time_id == 3), ...
      S_part_a(time_id==3), ...
      ones(sum(time_id==3),1)*S_error_a, ...
      'ro', 'markerfacecolor', 'r');

   h.errorbar_part_b = errorbar(time(time_id == 4), ...
      S_filled(time_id==4), ...
      ones(sum(time_id==4),1)*S_error_b, ...
      'bo', 'markerfacecolor', 'b');

   h.legend = legend('Final series','SSA-filling-a','SSA-filling-b', ...
      'location','best');
   title(sprintf('Optimal parameter: M=%d, K=%d',opt_MK));
   datetick

   if nargout == 1
      varargout{1} = h;
   end
end
