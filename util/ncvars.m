function vars = ncvars(fname)
%NCVARS extracts the variable names in a netcdf file
%   vars = ncvars(fname) is a wrapper for extractfield

%     Author: matt cooper (matt.cooper@pnnl.gov)

info    =   ncinfo(fname);
vars    =   extractfield(info.Variables,'Name');

end

