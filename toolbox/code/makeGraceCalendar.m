function [Time, Time_referencePeriod] = makeGraceCalendar(Time_notFilled, kwargs)

   arguments
      Time_notFilled
      kwargs.calendarType {...
         mustBeMember(kwargs.calendarType, ["gapfilled", "notfilled"])} ...
         = "gapfilled"
      kwargs.referencePeriodStart (1, 1) datetime = datetime(2004, 1, 1)
      kwargs.referencePeriodEnd (1, 1) datetime = datetime(2009, 12, 31)
   end

   % Make a calendar for the gap-filled data. Note: If input Time_notFilled is
   % posted mid-month then Time_gapFilled will be ~mid-month too.
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

   % New
   regularTime_notFilled = dateshift(Time_notFilled, "start", "month");

   regularTime_gapFilled = mkcalendar(...
      datetime(year(Time(1)), month(Time(1)), 1), ...
      datetime(year(Time(end)), month(Time(end)), 1), ...
      calmonths(1));

   % technically 18 Apr, some round up an dreport May 2002
   grace_begin = datetime(2002, 4, 1);
   grace_end = datetime(2017, 6, 30);
   gfo_begin = datetime(2018, 6, 01);
   gfo_end = regularTime_gapFilled(end); % still active, I think

   % May 2002 to June 2017 - GRACE
   % July 2017 to May 2018 - 11 months gap
   % June 2018 to present - GRACE-FO

   gfoTime = isbetween(regularTime_gapFilled, gfo_begin, gfo_end);
   graceTime = isbetween(regularTime_gapFilled, grace_begin, grace_end);
   missingTime = ~ismember(regularTime_gapFilled, regularTime_notFilled);
   betweenTime = isbetween(regularTime_gapFilled, grace_end, gfo_begin, 'open');

   assert(sum(betweenTime) == 11)
   assert(none(gfoTime & graceTime & missingTime & betweenTime))
   assert(sum(gfoTime | graceTime | missingTime | betweenTime) ...
      == numel(regularTime_gapFilled))

   flags = zeros(numel(regularTime_gapFilled), 1);

   flags(graceTime, 1) = 1;
   flags(gfoTime, 1) = 2;
   flags(missingTime & graceTime, 1) = 3;
   flags(betweenTime, 1) = 4;

   info = timetable(flags, graceTime, missingTime, betweenTime, gfoTime, ...
      'RowTimes', regularTime_gapFilled, 'VariableNames', ...
      {'flags', 'isgrace', 'isgracemissing', 'isbetween', 'isgfo'});

   % How it's done in graceGapFill:
   % id(t0<2017.5 & ~inan) = 1; % 1: GRACE
   % id(t0>2017.5 & ~inan) = 2; % 2: GFO
   % id(t0<2017.5 & inan) = 3;  % 3: gaps within GRACE
   % id(t0>2017.5 & inan) = 4;  % 4: the 11-month gap & a gap within GFO

end
