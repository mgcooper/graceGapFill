function [datetimes,datenums] = decimalyear2datetime( decimalyears )
    
%     mgc: this was an answer on the community forum, I renamed it
%     decyear2date and added some stuff

  yr        = floor(decimalyears);
  decYr     = mod(decimalyears,1);
  date0     = datenum(num2str(yr),'yyyy');
  date1     = datenum(num2str(yr+1),'yyyy');
  daysInYr  = date1 - date0;
  datenums  = date0 + decYr .* daysInYr;
  datetimes = datetime(datenums,'convertfrom','datenum');
end