% Chord Recognition Project @ CCRMA 2014
% Sub module 1: Get Spectrogram
% desc: get the constant-Q squared-magnitude spectrogram from the audio wave

function [mySpec,fc,nocts,M,R] = getSpec(wave,fs,constantQ,fmin,binsPerSemitone,doPlot,doPause)
% inputs:
%        wave            - mono audio vector (Nx1 or 1xN matrix)
%        fs              - sampling rate of wave (Hz)
%        fmin            - minimum frequency (e.g., 41.2 Hz for bass guitar)
%        constantQ       - 0 for uniformly spaced filter bank, 1 for const Q
%        binsPerSemitone - number of bins in 1st semitone (all when constantQ)
%        doPlot          - 0 for no plots, 1 to plot spectrogram
%        doPause         - 0 for no pauses, 1 to pause sometimes
% output:
%        mySpec - squared-magnitude spectrogram (1st column = 1st frame, etc.)
%        fc     - center-frequencies of the filter bank
%        nocts  - number of full octaves from fmin to fs/2 (for convenience)
%        M      - window length used in FFTs
%        R      - hop size used

%% Create log-frequency filterbank:

% Calculate filter-bank center frequencies:
nocts = floor(log2(0.5*fs/fmin));     % Integer number of full octaves (was Z=4)
if nocts<1, error('getSpec: Must have at one full octave between fmin and fs/2'); end
if constantQ
  nFilters = binsPerSemitone*12*nocts;                 % Number of filters in filter bank
  fc = fmin*2.^([0:nFilters-1]/(binsPerSemitone*12));  % Filter center frequencies
  Q  = 1/(2^(1/(binsPerSemitone*12))-1);               % Desired Q factor (Q=fc/bandwidth)
  nFFT = 1; % will be set below
else
  trueFmin = fmin*2^(-1/(binsPerSemitone*12));   % fmin in middle of first group
  fmax = fmin * 2^nocts;
  trueFmax = fmax*2^(1/(binsPerSemitone*12));    % fmax in middle of last group
  df = trueFmin*(2^(1/(binsPerSemitone*12))-1)   % frequency sampling interval
  nFFT = 2^nextpow2(ceil(fs/df))
  iMin = 1 + round(nFFT * trueFmin / fs); % index closest to fmin in FFT output
  iMax = 1 + round(nFFT * trueFmax / fs);
  iAxis = [iMin:iMax];
  fAxis = [0:nFFT/2-1] * fs / nFFT;
  fc = fAxis(iMin:iMax);
  clear Q; % in case we're a script and it exists from a previous run
end

% Create STFT

min_delta_f = fc(2)-fc(1); % smallest resolution step we'll need
resolutionFactor = 0.5; % set to 1.0 for "proper" resolution
%resolutionFactor = 0.11278; % Yields M=512 for fs=44100/10 to match Kitty's original value
windowFactor = 4;   % 4 for Hamming, 6 for Blackman, etc. - see SASP
facs = resolutionFactor * windowFactor;
M = ceil(facs*fs/min_delta_f); % Window length for desired resolution
disp(sprintf('Window length is %0.3f seconds = %d samples',M/fs,M)); 
zpf = 2; % zero-padding factor (extra spectral interpolation)
Nfft = max(nFFT,2^nextpow2(M*zpf)); % FFT size
R = round(M/4); % Hop size (was M/2)
disp(sprintf('Window hop size is %0.3f seconds = %d samples',R/fs,R)); 
window = hamming(M);
nWave = length(wave);
if M>nWave
  error(sprintf(...
      'signal must be at least one window long = %d samples = %0.1f sec',...
      M,M/fs)); 
end
% Not defined in Octave: spectrogram(wave, window, M-R, Nfft,fs);
% Defined in both Matlab + SPTB and Octave + octave-signal package:
STFT = specgram(wave, Nfft, fs, window, M-R);
STFTmagsq = abs(STFT) .^ 2; % We want to sum power in each band
[nFreqs,nFrames] = size(STFT);
freqs = fs * [0:nFreqs-1]/Nfft;
times = [0:nFrames-1] * R / fs;
times = times + 0.5 * R / fs; % Convert to frame center instead of start

screensize = get(0,'screensize');
figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner

if doPlot
  % Plot the Spectrogram for interactive perusal:
  Sdb = dbn(STFT);
  % figure(); % Waterfall:
  % plot(freqs,Sdb + ones(length(freqs),1)*[0:nFrames-1]*50);
  % xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
  figure('position',figPos);
  mesh(times,freqs,Sdb);
  title('getSpec: STFT Spectrogram (dB)');
  xlabel('Time (s)');
  ylabel('Frequency (Hz)');
  zlabel('Magnitude (dB)');
  if doPause, disp('PAUSING'); pause; end
end

if ~constantQ
  iMin = 1 + round(Nfft * trueFmin / fs); % index closest to fmin in FFT output
  iMax = 1 + round(Nfft * trueFmax / fs);
  iAxis = [iMin:iMax];
  fAxis = [0:Nfft/2-1] * fs / Nfft;
  fc = fAxis(iMin:iMax);
  mySpec = STFTmagsq(iMin:iMax,:);
else
  %Scale and map to bin
  resolution = fs/Nfft;     % Frequency resolution in Hz of each FFT bin
  f_bin = fc/resolution; % Get center-frequencies in bins

  % Create CQ filterbank:
  log_filters = zeros(nFilters, nFreqs);
  for i = 1 : nFilters
    curr = f_bin(i); % current filter center-frequency bin fc
    if i == 1
      prev = curr - (f_bin(i+1)-curr); % make first band symmetric
    else
      prev = f_bin(i-1); % Previous fc bin
    end
    if i == nFilters
      next = curr + (curr-f_bin(i-1)); % symmetric last band as well
    else
      next = f_bin(i+1); % Next fc bin 
    end
    lsamps = floor(curr) : -1 : floor(prev);
    lsampsz = lsamps - curr;
    winL = 0.5+0.5*cos(pi*lsampsz/(curr-prev)); % window for left half
    rsamps = ceil(curr : next-1);
    rsampsz = rsamps-curr;
    winR = 0.5+0.5*cos(pi*rsampsz/(next-curr)); % window for right half
    winLR = [fliplr(winL),winR];
    normalization = max(winLR);
    % normalization = sum(winLR);
    % normalization = sqrt(sum(winLR .^ 2)); % equal power in each band
    lweighting = 1; % Loudness weighting happens in a later function
    log_filters(i,lsamps) = winL * lweighting / normalization;
    log_filters(i,rsamps) = winR * lweighting / normalization;
    if doPlot*0
      if i == 1, figure('position',figPos); end
      flsamps = fliplr(lsamps);
      allsamps = [flsamps,rsamps];
      plot(allsamps,log_filters(i,allsamps),'-k*'); grid('on');
      g = 1/normalization;
      % hold('on'); plot(flsamps,g*fliplr(winL),'+'); plot(rsamps,g*winR,'o'); plot(allsamps,g*winLR,'x');
      title(sprintf('getSpec: Filter channel %d',i));
      xlabel('Frequency (bins)');
      ylabel('Gain (linear)');
      if doPause, disp('PAUSING'); pause; end
      hold('off');
    end
  end

  if doPlot
    figure('position',figPos);
    plot(freqs,log_filters,'-k'); grid('on'); % axis('tight');
    hold('on');
    plot(freqs,sum(log_filters),'-k');
    plot([fs/2,fs/2],[0,1],'--k');
    ttl=sprintf('getSpec: Constant-Q Filter Bank + Linear Sum, fs=%d, fmin=%0.1f, binsPerSemitone=%d',fs,fmin,binsPerSemitone);
    title(ttl);
    xlabel('Frequency (Hz)');
    ylabel('Gain (linear)');
    if doPause, disp('PAUSING'); pause; end
    hold('off');
    figure('position',figPos);
    dpybins = find(freqs>=fmin*0.8);
    semilogx(freqs(dpybins),log_filters(:,dpybins),'-k'); grid('on'); % axis('tight');
    hold('on');
    filter_sum = sum(log_filters);
    semilogx(freqs(dpybins),filter_sum(dpybins),'-k');
    semilogx([fs/2,fs/2],[0,1],'--k');
    ttl=sprintf('getSpec: Constant-Q Filter Bank + Linear Sum, fs=%d, fmin=%0.1f, binsPerSemitone=%d',fs,fmin,binsPerSemitone);
    title(ttl);
    xlabel('Frequency (Hz)');
    ylabel('Gain (linear)');
    if doPause, disp('PAUSING'); pause; end
    hold('off');
  end

  % convert to log-freq spectrogram:
  mySpec = log_filters * STFTmagsq; % Matrix Multiplication => filter bank output

  % FIXME: Recall from Music 420A that summing bin powers over a band
  % REDUCES the effective window duration for that band.  As a result,
  % we should choose the hop size according to the widest band computed.
  % At present, we simply undersample the time axis.  Note that
  % transient frames should become a smaller fraction of total frames if
  % this is done.

  if doPlot
    figure('position',figPos);
    %1. Plot STFT Spectrogram
%    subplot(2,1,1);
    imagesc(0.5*dbn(STFTmagsq,-100));
    ylabel('Frequency (samples)');
    title('getSpec: STFT Spectrogram (dB)');
    set(gca,'YDir','normal');
    set(gca,'XTick',1:100:M-1);  %Set: show a number every 100 numbers
    secs = ((1:100:M)-1) * R/fs; %Convert X axis from frame to time
    set(gca,'XTickLabel',num2str(round(secs(:)))); %Round to seconds
    xlabel('Time (sec)');
    if doPause, disp('PAUSING'); pause; end
  end

end

if doPlot
  figure('position',figPos);
  % imagesc(0.5*dbn(mySpec,-100));
  MSdb = dbn(mySpec,-100);
  mesh(times,fc,MSdb);
  xlabel('Time (seconds)');
  ylabel('Frequency (Hz)');
  title('getSpec: Filter Bank Outputs (dB)');
  set(gca,'YDir','normal');
  set(gca,'XTick',1:100:M-1);
  secs = ((1:100:M)-1) * R/fs;
  set(gca,'XTickLabel',num2str(round(secs(:))));
  if doPause, disp('PAUSING'); pause; end
end

