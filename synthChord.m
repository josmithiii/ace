function s = synthChord(f00,intervals,nharms,dur,fs)

% inputs
%   f00       - fundamental (Hz)
%   intervals - semitones up from f00
%   nharms    - number of harmonics to synthesis (1 for sine)
%   dur       - duration in seconds
%   fs        - sampling rate (Hz)
%
% output
%   s         - unit-amplitude signal

f0s = f00 * 2 .^ (intervals/12);
t = [0:1/fs:dur];
s = zeros(1,length(t));
for i=1:length(f0s)
  f0 = f0s(i);
  s = s + sin(2*pi*f0*t);
  for h=2:nharms
    s = s + sin(2*pi*(h*f0)*t)/h; % sawtooth spectrum
  end
end
s = s / max(abs(s));
