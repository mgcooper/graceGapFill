function varargout = dealout(varargin)
   %DEALOUT deal comma separated list, struct, or cell to comma separated list
   %
   %    [argout1, argout2] = dealout(argin1, argin2, ..., arginN]
   %    [cellArrayOutput{1:nargout}] = dealout(argin1, argin2, ..., arginN)
   %    [cellArrayOutput{1:nargout}] = dealout(cellArrayInput{:})
   %
   %    cellArrayOutput = dealout(cellArrayInput)
   %    cellArrayOutput = dealout(structInput)
   %
   %  Description
   %    In general, dealout acts like deal with one critical difference: The
   %    number of outputs *does not* have to match the number of inputs, but
   %    outputs are dealt out in the exact order they are dealt in i.e.,
   %    argout1=argin1, argout2=argin2, and so on. Depending on the syntax, the
   %    number of requested outputs can exceed inputs: this occurs when a single
   %    input - a cell array or struct array - is provided to dealout, and
   %    multiple outputs are requested. In this case, the individual elements or
   %    fields of the cell or struct array are dealt out.
   %
   %    Use dealout to parse function outputs with a single line:
   %
   %       [varargout{1:nargout}] = dealout(arg1, arg2, arg3, ..., argN);
   %
   %    where N >= nargout. Note that no outputs will be dealt if nargout=0.
   %
   %    Compare that with how a typical matlab function might deal its outputs:
   %
   %       switch nargout
   %          case 0
   %          case 1
   %             varargout{1} = arg1;
   %          case 2
   %             varargout{1} = arg1;
   %             varargout{2} = arg2;
   %          case 3
   %             varargout{1} = arg1;
   %             varargout{2} = arg2;
   %             varargout{3} = arg3;
   %       end
   %
   %    ... and so forth. This might be simplified somewhat to:
   %
   %          if nargout > 0
   %             varargout{1} = arg1;
   %             switch nargout
   %                case 2
   %                   [varargout{1:2}] = deal(arg1, arg2);
   %                case 3
   %                   [varargout{1:3}] = deal(arg1, arg2, arg3);
   %             end
   %          end
   %
   %    Note the critical difference here: the number of inputs to deal must
   %    match the number of outputs.
   %
   %    Special cases: Struct input and scalar cell inputs
   %    --------------------------------------------------
   %    dealout supports two special cases to simplify output parsing further:
   %    If a single argument is supplied to dealout and it is a struct array or
   %    a cell array, the struct fields or cell elements will be dealt out. The
   %    latter case requires special care by the user and is potentially error
   %    prone: If a function ends with
   %
   %       [varargout{1:nargout}] = dealout(cellargs)
   %
   %    then the individual elements of cellargs will be returned as individual
   %    elements of varargout, but *only if* nargout <= numel(cellargs{:}). In
   %    this case, it should become apparent to the developer that something is
   %    wrong, and the intended syntax can be used instead:
   %
   %       [varargout{1:nargout}] = dealout(cellargs{:})
   %
   %    If the syntax [varargout{1:nargout}] = dealout(cellargs) is used, a
   %    warning is issued with warnID "custom:dealout:ScalarCellInput". If this
   %    syntax is intended, developers can suppress this warning message within
   %    their function bodies.
   %
   % ------------------------------------------------------------------------
   %  This is no longer applicable to the standard comma separated list example
   %  given in the beginning b/c output is suppressed if [varargout{1:nargout}]
   %  is used on the LHS. However, this may be applicable to the scalar
   %  cell/struct input case, so I replaced the csl with CellArrayInput. Update
   %  this when time allows.
   %
   %    If the function is not designed to supress outputs when nargout == 0:
   %
   %       varargout = dealout(CellArrayInput);
   %
   %    To suppress outputs when nargout == 0:
   %
   %       if nargout
   %          varargout = dealout(CellArrayInput);
   %       end
   % ------------------------------------------------------------------------
   %
   %  Examples
   %
   %       function varargout = myfunction(varargin)
   %
   %           ... function code which creates three arguments
   %
   %           if nargout
   %               varargout = dealout(arg1, arg2, arg3);
   %           end
   %       end
   %
   %
   %       function varargout = myfunction(varargin)
   %
   %           ... function code which creates a cell array of arguments
   %
   %           if nargout
   %               varargout = dealout(cellargs{:});
   %           end
   %       end
   %
   %    In both cases above, the "if nargout ..." check can be excluded, and
   %    [varargout{1:nargout}] can be used instead:
   %
   %       function varargout = myfunction(varargin)
   %
   %           ... function code which creates three arguments
   %
   %           [varargout{1:nargout}] = dealout(arg1, arg2, arg3);
   %       end
   %
   % Matt Cooper, 22 Jun 2023
   %
   % See also: deal

   args = varargin;

   % Special case 1: single struct array input
   %
   % This is designed to eliminate the following calling syntax, where opts is a
   % name-value struct with N pairs:
   %
   %    vals = struct2cell(opts);
   %    [val1, val2, ..., valN] = dealout(vals{:})
   %
   % Instead, users can simply pass opts directly to dealout:
   %
   %    [val1, val2, ..., valN] = dealout(opts)
   %
   % If the first calling syntax is used, struct2cell produces a cell-array with
   % one element per name-value pair in opts (as expected), but if the calling
   % function tries to use the one liner:
   %
   %    [val1, val2, ..., valN] = dealout(struct2cell(opts))
   %
   % then the cell array will be nested inside varargin here which will be a
   % scalar cell-array, with the desired cell-array its only element, rather
   % than a comma separated list.

   wasonestruct = nargin == 1 && isstruct(args{1});
   wasonecell = nargin == 1 && iscell(args{1});

   if wasonestruct
      try
         args = struct2cell(args{:});
      catch e

      end
   end

   % Require fewer or same outputs as inputs (but not vise versa).
   if nargout > numel(args)
      eid = 'custom:dealout:OutputsExceedInputs';
      emsg = 'Number of requested outputs cannot exceed the number of inputs.';

      % This throws the same issue the try-catch handles, so deactivated it.
      % error(eid, emsg)
   end

   % Deal elements of cell array args to varargout, in order.
   warnflag = false;
   try
      % Syntax is [out1, out2, ..., outN] = dealout(in1, in2, ..., inN]
      [varargout{1:nargout}] = deal(args{1:nargout});

      warnflag = wasonecell && nargout == 1;
      % Syntax is varargin = dealout(CellArray) (works in all cases)
      %
      % OR, [varargout{1:nargout}] = deal(CellArray) (fails in one case)
      %
      % The latter works as intended EXCEPT one case: the caller requests one
      % output, but CellArray contains multiple arguments intended to be dealt
      % to multiple outputs. In that case, the entire CellArray is returned.

   catch e
      % Syntax is [out1, out2, ..., outN] = dealout(CellArray)
      % assert(wasonecell || wasonestruct)
      varargout = args{:};

      % The warning should not be needed here. This is the case that works
      % whether varagout or [varargout{1:nargout}] is used, and nargout>1,
      % because if nargout = 1, it doesn't catch.
   end

   if warnflag

      wid = 'custom:dealout:ScalarCellInput';
      msg = ['%s received a single cell array as input. Ensure the ' ...
         'following syntax is used in the calling function:\n ' ...
         '  varargout = dealout(CellArray) \n' ...
         ' or use the following syntax with comma separated list input: \n' ...
         '  [varargout{1:nargout}] = dealout(CellArray{:}) \n' ...
         'See the documentation for DEALOUT for more information.'];

      warning(wid, msg, mfilename)


      % This is the case where the code doesn't fail but is error prone
      % if the calling function uses the syntax:
      %
      %  [varargout{1:nargout}] = dealout(CellArrayOfFunctionOutputs)
      %
      % The error occurs when the caller of the calling function requests a
      % single output (so nargout == 1), and the try DOES NOT FAIL, b/c
      % nargout=1 and numel(args)=1, but args is actually multiple args
      % packed into CellArrayOfFunctionOutputs. In this case, deal packs the
      % entire CellArrayOfFunctionOutputs into varargout{1}.
      %
      % Compare that with the behavior when the caller of the calling
      % function requests two or more outputs. Then nargout>1 but
      % numel(args)=1, so the try DOES FAIL, and the catch step expands
      % args{:}, and each element of CellArrayOfFunctionOutputs is dealt into
      % a single element of varargout.
      %
      % Since it is impossible to know whether the calling function used the
      % error prone syntax:
      %     [varargout{1:nargout}]=dealout(CellArrayOfFunctionOutputs)
      % Or the correct syntax:
      %     varargout = dealout(CellArrayOfFunctionOutputs)
      % The warning message would need to include this information. It only
      % needs to be issued if nargout == 1, BUT THE PROBLEM IS THAT NARGIN=1
      % WHEN THE CORRECT SYNTAX IS USED varargout = dealout(CellArray). So
      % it's annoying to have the message. So I may turn it off.
   end

   % % Original message:
   % wid = 'custom:dealout:ScalarCellInput';
   % msg = ['%s expects comma separated list input but received a ' ...
   %    'single cell array. Dealing each cell array element as output. ' ...
   %    'Consider using comma separated list input: dealout(cellinput{:})'];

   % Note: this syntax forces one output, and may prevent errors or unexpected
   % behavior, but requires the calling function to use nargout checks.
   %
   % [varargout{1:max(1,nargout)}] = deal(varargin{1:nargout});

   % TODO:
   % Compare with this format:
   % if ~iscell(x), x = num2cell(x); end
   % varargout = cell(1,nargout);
   % [varargout{:}] = deal(x{:});
end
