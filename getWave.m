% Chord Recognition Project @ CCRMA 2014
% Get Wave data from file
% desc: load the audio file, creating a cached downsampled version if needed

function wave = getWave(wavenameroot,fsds,wavdir,wavdsdir)
% inputs:
%        wavenameroot - filename body (no '.wav' extension)
%        fsds         - sampling rate of wavefile (Hz) desired AFTER DOWNSAMPLING
%        wavdir       - optional directory of .wav audio files
%        wavdsdir     - optional directory of DOWNSAMPLED .wav audio files
% output:
%        wave         - downsampled wave data, converted to mono if necessary

if nargin<3
  wavdir = './';
end
if nargin<4
  wavdsdir = wavdir;
end

wavepath = [wavdir,wavenameroot,'.wav']; % original version
wavedspath = [wavdsdir,wavenameroot,'DS.wav']; % downsampled version

if exist(wavdsdir)~=7, mkdir(wavdsdir); end
if exist(wavedspath)==2 % downsampled file exists - use it:
  disp(sprintf('Loading cached downsampled mono file %s',wavedspath));
  [wave,fs,wordlength] = wavread(wavedspath); % Read audio file
  nchans = size(wave,2);
  if nchans ~= 1 || fs ~= fsds
    error(sprintf('getWave: Delete cached downsampled-mono file %s and try again',wavepath));
  end
else % create downsampled mono version:
  disp(sprintf('Loading file %s',wavepath));
  if exist(wavepath)~=2
    error(sprintf('Cannot find .wav file ./%s',wavepath));
  end
  [wave,fs,wordlength] = wavread(wavepath); % Read the audio file
  nchans = size(wave,2);
  if nchans>1
    wave = sum(wave,2); % convert to mono if multichannel
  end
  if fs ~= fsds
    wave = resampleSomehow(wave,fsds,fs);
    wavwrite(wave,fsds,wavedspath); % cache for later usage
  else
    disp('getWave: No downsampling needed');
  end

  % We prefer not to normalize since loudness models prefer calibrated
  % signals, typically in Pascals. We can normalize when playing back
  % as needed.  However, since the downsampled signal is saved in a
  % wav file, it cannot exceed 1 in magnitude:
  wavemax =  max(abs(wave));
  if wavemax > 1
    warning(sprintf('getWave: Must normalize due to maximum amplitude = %f',wavemax));
    wave = wave / wavemax;
  end
end
