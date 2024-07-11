function psdx = powerSpectralDensity(x,varargin)
   %POWERSPECTRALDENSITY Compute the power spectral density
   %
   %  psdx = powerSpectralDensity(x,varargin)
   %
   % See also

   parser = inputParser();
   parser.FunctionName = mfilename;
   parser.CaseSensitive = false;
   parser.KeepUnmatched = true;

   parser.addRequired('x', @isnumeric);
   parser.addParameter('t', 1, @isnumeric);
   parser.parse(x, varargin{:});
   t = parser.Results.t;

   % % based on:
   % openExample('signal/PowerSpectralDensityEstimatesUsingFFTExample')
   % right now this just applies to the first example, a one-sided real-valued
   % signal

   % % mgc: this is the example setup, Fs is the sampling frequency, so for
   % this function I require input x and optional input t, where x is the
   % signal and t is the sample points (time), so the frequency is diff(time)
   % rng default
   % Fs = 1000;
   % t = 0:1/Fs:1-1/Fs;
   % x = cos(2*pi*100*t) + randn(size(t));

   % mgc begin: these first checks on t and Fs are ad hoc, not sure we want
   % them, but in general i think we want the ability to pass in an arbitrary
   % time and signal pair (t,x) and get the sampling frequency Fs to perform
   % the recommended scaling

   % if t is not provided, create a vector from 1:numel(x)
   if t == 1
      t = cumsum(ones(size(x)));
   end

   % compute the sampling frequency
   Fs = 1./diff(t);
   if any(Fs ~= Fs(1))
      error('irregular sampling frequency detected')
   else
      Fs = Fs(1);
   end

   % Obtain the periodogram using fft. The signal is real-valued and has even
   % length. Because the signal is real-valued, you only need power estimates
   % for the positive or negative frequencies. In order to conserve the total
   % power, multiply all frequencies that occur in both sets — the positive
   % and negative frequencies — by a factor of 2. Zero frequency (DC) and the
   % Nyquist frequency do not occur twice. Plot the result.
   N = length(x);
   xdft = fft(x);
   xdft = xdft(1:N/2+1);
   psdx = (1/(Fs*N)) * abs(xdft).^2;
   psdx(2:end-1) = 2*psdx(2:end-1);

   % % this can be used to compare with the example
   %    freq = 0:Fs/length(x):Fs/2;
   %    figure;
   %    plot(freq,10*log10(psdx)); grid on;
   %    title('Periodogram Using FFT');
   %    xylabel('Frequency (Hz)','Power/Frequency (dB/Hz)');
end
