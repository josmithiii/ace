% Make test chord using sinusoids
fs = 44100;
dur = 1; % duration of each chord in sec
nharms = 1; % 1 for sine, else sawtooth-like spectrum

if 0 % simple octaves test (basic reality check)
  ds = 1; % downsampling factor expected
  fsds = fs/ds;
  f00 = fsds / 16;
  intervals1 = [0 12 36]; % octaves
  intervals2 = intervals1;
else
  f00 = 440;   % fundamental frequency (Hz)
  intervals1 = [0 4 7]; % A triad
  intervals2 = [0 5 9]; % D triad first inversion
end

s1 = synthChord(f00,intervals1,nharms,dur,fs);
s2 = synthChord(f00,intervals2,nharms,dur,fs);
s = [s1,s2];
wavwrite(s(:),fs,'chord.wav');
delete chordDS.wav;

soundsc(s,fs);

plotSpectrum(s,fs)
