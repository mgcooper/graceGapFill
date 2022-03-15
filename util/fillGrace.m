function data = bfra_fillGRACE(time,S,opts)
   
    % INPUTS:
    %   time    = datetime array of GRACE data
    %   S       = numeric array of GRACE time series
    %   opts    = structure of options, see below for options
    
    %   S can be an array of size numPoints x numTimesteps
    %   size(S,2) must match numel(time) i.e., time across the column
    
    % these are the original notes from Shuang's script. I renamed 
    % tt1:      equal-spaced time
    % X1:       rearranged S, NaN is assigned to gaps
    % X2:       results after SSA-filling-a gaps (id = 3) are filled.
    % verror1:  error estimation, based on fitting residuals
    % X3:       final output, all gaps are filled
    % verror2:  error esimation, based on the cross validation (if implemented, 
    %           otherwise based on fitting residuals).
    
    % Author: Shuang Yi, shuangyi.geo@gmail.com, 05/12/2021
    
    % (Converted to a function by Matt Cooper matt.cooper@pnnl.gov with
    % some extra functionality)
    
    % This function implements the GRACE gap-filling algorithm in the
    % reference below. The function is based on the script that comes with
    % the repo 'main_SSA_gap_filling.m'. 
    
    % Reference:
    % "Filling the data gaps within GRACE missions using Singular Spectrum Analysis"
    % Journal of Geophysical Research: Solid earth
    % Shuang Yi, Nico Sneeuw
    % https://doi.org/10.1029/2020JB021227
    % ---
    % Shuang Yi, shuangyi.geo@gmail.com, 05/12/2021
    
    
% parse the inputs
    if nargin==2
        plotFigs = false;
        saveFigs = false;
        showFigs = false;
    elseif nargin == 3 && isstruct(opts)
        plotFigs = opts.plotFigs;
        saveFigs = opts.saveFigs;
        showFigs = opts.showFigs;
        pathSave = opts.pathSave;
    end

    
    MM      = 24; % Window size
    KK      = 10; % Maximum number of RCs to be used
    Mlist   = 24:12:96; 
    Klist   = [1,2:2:12]; 
    
    
    [~,decday]  = date2doy(datenum(time)); 
    decyear     = year(time) + decday; 

    ser(:,1)    = decyear;  % time in decimal years

    % find the unique values - Major improvement in runtime. Note - this
    % is applicable to the case whre you first interpolate the raw Grace
    % data to a set of points, e.g. a basin shapefile, and the points have
    % identical data, b/c the Grace data is itself an interpolated product
    % and adjacent 'grid cells' sometiems have identical data, so there's
    % no point in running the slow algorithm over identical data, or
    % because the interpolation points you used are at a smaller spatial
    % resolution than the raw data, so they all just equal the single grace
    % point they are nearest (assumes you used nearest neighbor)
    [S0,iSa,iSb] = unique(S(:,1));
    
    numUnique   = numel(S0);        
    numPerVal   = nan(numUnique,1);
    for n = 1:numUnique
        numPerVal(n) = sum(S(:,1)==S0(n));
    end
    
    
    nS          = size(S,1);
    Sfilled     = nan(nS,231);
    verr        = nan(nS);
    S1          = nan(nS,231);
    S2          = nan(nS,231);
    
   %for n = 1:nS
    for n = 1:numUnique % mgc only gap-fill the unique values

       %ser(:,2)    = S(n,:);   % grace twsa, I am guessing
        ser(:,2)    = S(iSa(n),:);   % grace twsa data for this point

        % generate uniformly spaced time series
        [tt1,X1]    = uniform_time(ser(:,1),ser(:,2), [2002,4,2021,6]);

        %~~~~~~~~~~~~~~~~~~~~~~
        %   SSA-filling-a 
        %~~~~~~~~~~~~~~~~~~~~~~
        ind_nan     = isnan(X1);
        id          = zeros(size(tt1)); % classify observations and gaps by id

        id(tt1<2017.5 & ~ind_nan)   = 1; % 1: GRACE
        id(tt1>2017.5 & ~ind_nan)   = 2; % 2: GFO
        id(tt1<2017.5 & ind_nan)    = 3; % 3: gaps within GRACE
        id(tt1>2017.5 & ind_nan)    = 4; % 4: the 11-month gap & a gap within GFO

        [X2,verror1] = fun_SSA_filling_a(X1,id, MM, KK);

        %~~~~~~~~~~~~~~~~~~~~~~
        %   SSA-filling-b 
        %~~~~~~~~~~~~~~~~~~~~~~

        % The following code traverses Mlist & Klist to implement the cross
        % validation to find the optimal parameter set. If both Mlist and Klist
        % consist of only one element, the value will be used directly.
       %fprintf('wait for cross validation: iter = %d out of %d\n',n,nS);
        fprintf('wait for cross validation: iter = %d out of %d\n',n,numUnique);
        [X3,verror2,opt_MK] = fun_SSA_filling_b(tt1,X2,Mlist,Klist);

        %~~~~~~~~~~~~~~~~~~~~~~
        %   plot
        %~~~~~~~~~~~~~~~~~~~~~~
        if plotFigs == true
            if n == 1
                if showFigs == false
                    figure('position',[1,1,1028,303],'Visible','off');
                else
                    figure('position',[1,1,1028,303],'Visible','on');
                end
            end

            plot(tt1,X3,'o-','color',[1,1,1]/2); hold on;
            errorbar(tt1(id == 3),X2 (id==3), ones(sum(id==3),1)*verror1,   ...
                        'ro','markerfacecolor','r');
            errorbar(tt1(id == 4),X3 (id==4), ones(sum(id==4),1)*verror2,   ...
                        'bo','markerfacecolor','b');
            legend('Final series','SSA-filling-a','SSA-filling-b','location','best');
            title(sprintf('Optimal parameter: M=%d, K=%d',opt_MK));
            if saveFigs == true
                export_fig([pathSave 'gap_filled_' int2str(n) '.png'],'-r400');
            end

            if showFigs == true; pause; end; clf;
        end

        idx_n = find(iSb==n);
        for m = 1:numel(idx_n)
            S1(idx_n(m),:)         = X1;
            S2(idx_n(m),:)         = X2;
            Sfilled(idx_n(m),:)    = X3;
            verr(idx_n(m),1)       = verror1;
            verr(idx_n(m),2)       = verror2;
            optMK(idx_n(m),:)      = opt_MK;
        end

    end

    % retime the gapfilled data to a monthly calendar
    T           = decyear2date(tt1);
    T.Format    = 'dd-MMM-uuuu';

    data.S      = Sfilled;
    data.S1     = S1;
    data.S2     = S2;
    data.Serr   = verr;
    data.time   = T;
    data.optMK  = optMK;
    data.id     = id;
end
