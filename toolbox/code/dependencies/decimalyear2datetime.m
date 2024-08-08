function [datetimes, datenums] = decimalyear2datetime(decimalyears)

   decyr = mod(decimalyears, 1);
   year0 = floor(decimalyears);

   date0 = datenum(num2str(year0), 'yyyy');
   date1 = datenum(num2str(year0 + 1), 'yyyy');

   daysInYr = date1 - date0;
   datenums = date0 + decyr .* daysInYr;

   datetimes = datetime(datenums, 'convertfrom', 'datenum');
end
