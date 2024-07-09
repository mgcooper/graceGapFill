function S = ncparse(fname)
%PARSENC Parses a netcdf file - variable names, attributes, dimensions
%   S = parsenc(fname) returns the variable names, attributes, dimensions,
%   into a matlab structure S that is slightly more useful than the
%   standard output of ncinfo

%     Author: matt cooper (matt.cooper@pnnl.gov)

% this script just puts the standard ncinfo into a more accessible format
% it uses extractfield to get the variable names, which I have a hard time
% remembering to do, so this just makes it easier to get info out of the
% default structure that matlab's ncinfo returns

% also see: 'ncvars.m' which is just a wrapper for extractfield

info    =   ncinfo(fname);
S       =   table;
S.Name  =   (string({info.Variables.Name}))';
nvars   =   length(S.Name);

for n = 1:nvars
    
    % get the names of the attributes
    if isempty(info.Variables(n).Attributes)
        S.LongName{n}   =   nan;
        S.Units{n}      =   nan;
        S.Size{n}       =   nan;
        S.FillValue{n}  =   nan;
        S.Filename{n}   =   info.Filename;
        continue
    else
        atts    =   (string({info.Variables(n).Attributes.Name}))';
    end
    
    % if a longname exists, put it in the structure, else put nan
    ilongname           =   find(strcmp('long_name',atts));
    if isempty(ilongname)
        S.LongName{n}   =   nan;
    else
        long_n          =   info.Variables(n).Attributes(ilongname).Value;
        if isempty(long_n)
            S.LongName{n}  =   nan;
        else
            S.LongName{n}  =   long_n;
        end
    end    
    
    % if units exists, put it in the structure, else put nan
    iunits              =   find(strcmp('units',atts));
    if isempty(iunits)
        S.Units{n}      =   nan;
    else
        units_n         =   info.Variables(n).Attributes(iunits).Value;
        if isempty(units_n)
            S.Units{n}  =   nan;
        else
            S.Units{n}  =   units_n;
        end
    end    

    % if the size attribute exists, put it in the structure, else put nan
    size_n              =   info.Variables(n).Size;
    if isempty(size_n)
        S.Size(n)       =   {info.Variables(n).Size};
    else
        S.Size(n)       =   {info.Variables(n).Size};
    end
    
    % if the fill value exists, put it in the structure, else put nan
    fill_n              =   info.Variables(n).FillValue;
    if isempty(fill_n)
        S.FillValue{n}  =   nan;
    elseif ischar(fill_n)
        if strcmp(fill_n,'')
            S.FillValue{n}  =   nan;
        else
            S.FillValue{n}  =   info.Variables(n).FillValue;
        end
    elseif isnumeric(fill_n)
        S.FillValue{n}  =   info.Variables(n).FillValue;
    end
    
    S.Filename{n}       =   info.Filename;
end

end

