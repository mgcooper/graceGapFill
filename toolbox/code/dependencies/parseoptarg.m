function [opt, args, nargs] = parseoptarg(args, validopts, defaultopt)
   %PARSEOPTARG parse optional scalar text parameter in variable argument list.
   %
   %  [OPT, ARGS, NARGS] = PARSEOPTARG(ARGS, VALIDOPTS, DEFAULTOPT)
   %
   % Description
   %
   %  [OPT, ARGS, NARGS] = PARSEOPTARG(ARGS, VALIDOPTS, DEFAULTOPT) returns OPT,
   %  a char contained in ARGS found in VALIDOPTS, a new version of ARGS with
   %  OPT removed, and NARGS, the number of returned arguments in ARGS. If no
   %  elements of ARGS are found in VALIDOPTS, OPT is set to DEFAULTOPT.
   %
   %  If DEFAULTOPT is of type LOGICAL, then OPT is returned TRUE if an element
   %  of ARGS is found in VALIDOPTS and FALSE if ARGS does not contain an
   %  element in VALIDOPTS.
   %
   %  PARSEOPTARG is intended to isolate a single scalar text value OPT in
   %  functions using VARARGIN as the input argument, also known as a "flag".
   %  The behavior of PARSEOPTARG when DEFAULTOPT is of type LOGICAL allows the
   %  parsed OPT to be used as a logical switch in the calling function.
   %
   %  Note: this function requires the input ARGS to be passed in as 'varargin'
   %  rather than 'varargin{:}'.
   %
   % Inputs
   %
   %  ARGS - A cell array of arbitrary function input arguments. Nominally the
   %  'varargin' cell array in a calling function.
   %
   %  VALIDOPTS - A cell array, string array, or character vector of text
   %  scalars representing valid values for the optional argument.
   %
   %  DEFAULTOPT - The default value for the optional argument. This argument
   %  can be a text scalar (string or character vector) or a logical scalar.
   %
   % Outputs
   %
   %  OPT - The return value (parsed value) for the optional argument. If
   %  DEFAULTOPT is a text scalar, then OPT is returned as a text scalar. If
   %  DEFAULTOPT is a logical scalar, then OPT is returned as a logical scalar.
   %
   %  ARGS - The input ARGS with the parsed OPT removed (if found in ARGS).
   %
   %  NARGS - The number of elements in the output ARGS.
   %
   % Examples
   %
   %    function demo_function
   %    % Call the example calling_function
   %    calling_function('option2', 42, 'hello'); % 'option2' is selected
   %    calling_function(42, 'hello'); % 'option1' is selected as the default
   %    end
   %
   %    function calling_function(varargin)
   %    valid_options = {'option1', 'option2'};
   %    default_option = 'option1';
   %
   %    [selected_option, remaining_args, nargs] = parseoptarg( ...
   %       varargin, valid_options, default_option);
   %
   %    disp(['Selected option: ', selected_option]);
   %    disp(['Number of Remaining arguments: ', num2str(nargs)]);
   %    disp('Remaining arguments:');
   %    disp(remaining_args);
   %    end
   %
   % See also parseparampairs
   %
   % Changes
   % Jan 2024 - added logical flag feature.

   % PARSE INPUTS
   narginchk(2, 3)

   % Require that ARGS is a cell in case a user incorrectly passes varargin{:}
   % and it contains one element, or two elements with DEFAULTOPT omitted.
   assert(iscell(args))

   % Cast validopts to a cellstr if it is a string array or character vector.
   validopts = cellstr(validopts);

   % Set an empty default value for the opt arg.
   if nargin < 3
      defaultopt = '';
   end
   assert(isscalartext(defaultopt) || islogicalscalar(defaultopt))

   [args{1:numel(args)}] = convertStringsToChars(args{:});


   % MAIN
   for thisarg = transpose(validopts(:))
      % Find possible char opts and remove the matching one if found.
      iopt = cellfun(@(a) ischar(a), args);
      iopt(iopt) = cellfun(@(a) strcmp(a, thisarg), args(iopt));
      opt = args(iopt);
      args = args(~iopt);
      nargs = numel(args);

      if ~isempty(opt)
         opt = opt{:}; % since optarg is a scalar text, this should work
         break
      end
   end

   % PARSE OUTPUTS
   if isempty(opt)
      opt = defaultopt;
   else
      if islogical(defaultopt)
         opt = true;
      end
   end
end

% % For reference, this is a bit more intuitive
% ichar = cellfun(@(a) ischar(a), args);
% iopts = cellfun(@(a) strcmp(a, optarg), args(ichar));
% iargs = ~ichar;
% iargs(ichar) = ~iopt;
% optarg = args(~iargs);
% args = args(iargs);
