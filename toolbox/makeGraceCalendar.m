function [Time, Time_referencePeriod] = makeGraceCalendar(Time_notFilled, kwargs)

   arguments
      Time_notFilled
      kwargs.calendarType {...
         mustBeMember(kwargs.calendarType, ["gapfilled", "notfilled"])} ...
         = "gapfilled"
      kwargs.referencePeriodStart = datetime(2004,1,1)
      kwargs.referencePeriodEnd = datetime(2009,12,31)
   end

   % Make a calendar for the gap-filled data.
   Time_gapFilled = datetime( ...
      Time_notFilled(1):calmonths(1):Time_notFilled(end)+3);

   % Assign the requested period.
   switch kwargs.calendarType
      case "notfilled"
         Time = Time_notFilled;

      case "gapfilled"
         Time = Time_gapFilled;
   end

   % Make a calendar for the reference period (used to compute anomalies,
   % see the GRACE documentation).
   iref = isbetween(Time, ...
      kwargs.referencePeriodStart, kwargs.referencePeriodEnd);
   Time_referencePeriod = Time(iref);
end
