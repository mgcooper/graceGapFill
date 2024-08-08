function cleanupObj = withwarnoff(warningIDs)
   %WITHWARNOFF Temporarily disable warnings
   %
   % WITHWARNOFF('stats:nlinfit:IllConditionedJacobian') disables the warning
   % and reenables it when the calling function exits.
   %
   % cleanupObj = WITHWARNOFF('stats:nlinfit:IllConditionedJacobian') disables
   % the warning and reenables it when cleanupObj is destroyed.
   %
   % Note that it's not necessary for the function to return the onCleanup
   % object because it works automatically once it's created. However, you might
   % want to return it if you need to manually trigger the cleanup (by deleting
   % the object) or prevent the cleanup (by keeping a reference to the object so
   % it doesn't get deleted).
   %
   % Based on Andrew Janke's code.
   %
   % See also withcd, withjava

   arguments
      warningIDs string
   end

   % Save the current state of the warnings
   originalWarningState = warning;

   % Create a cleanup object that will be executed when the function is exited
   cleanupObj = onCleanup(@() warning(originalWarningState));

   % Turn off the specified warnings
   for n = 1:numel(warningIDs)
      warning('off', warningIDs(n));
   end

   % Note: varargout style return destroys the cleanupObj, so don't use it.
end

%% BSD 3-Clause License
%
% BSD 3-Clause License
%
% Copyright (c) 2023, Matt Cooper (mgcooper) All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
