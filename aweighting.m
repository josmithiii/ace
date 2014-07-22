% Source (and doc): http://en.wikipedia.org/wiki/A-weighting

% This A-weighting should be applied to the linear amplitude spectrum
% (not power spectrum or dB).  It is approximately equal to the
% inverse of the 40-phon equal-loudness curve of Fletcher and Munson,
% and also somewhat approximates the ISO 226:2003 update on that.
% Note that 40 phons is pretty quiet.

% The maximum gain is around 1.16 near 2.5 kHz, and for most
% frequencies the gain is less than 1.

function awt = aweighting(fc) % fc = sample frequencies in Hz

N = length(fc);
awt = zeros(1,N);
scl = 10^(2/20); % scaling to normalize max to 1 (at 1 kHz)
for n=1:N
  f = fc(n);
  awt(n) = scl * 12200^2 * f^4 / ...
           ( (f^2+20.6^2) * sqrt((f^2+107.7^2) * (f^2+737.9^2)) * (f^2+12200^2) );
end

if nargout==0
  plot(fc,awt,'-*')
  xlabel('Frequency (Hz)');
  ylabel('Amplitude (Linear)');
  title('A-weighting ~ inverse of Fletcher-Munson 40-phon equal-loudness curve');
end
