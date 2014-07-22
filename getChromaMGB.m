% function myChroma = getChromaMGB(loudSpec,tMGB,fMGB,fmin,fmax,binsPerSemiton,octaves,doPlot,doPause);
Nt = length(tMGB);
Nf = length(fMGB);
myChroma = zeros(binsPerSemitone*12*octaves,Nt);
CCounts = zeros(1,binsPerSemitone*12*octaves);

% Traverse frequency samples (binsPerSemitone*12 samples per octave) starting at
% fmin, summing all f0-support for that frequency.

f0 = fmin;
f0max = fmin*2^octaves;
f0scMax = fmax; % f0-support maximum frequency

% FIXME: Should switch to time-domain support (e.g. correlogram) at 
% high frequencies: support = correlation peak at 1/f0

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner
end

kc=1;
while f0<f0max
  f0s = zeros(1,Nt); % Support for f0 in the loudness spectrogram over all time
  f0sc = f0; % f0 support frequency
  k0sLast = 1;
  while f0sc < f0scMax
    k0s = findIndexBelow(fMGB,f0sc,k0sLast); % defined below
    k0sLast = k0s;
    eta = (f0sc-fMGB(k0s))/(fMGB(k0s+1)-fMGB(k0s)); % interpolation constant
    val = eta * loudSpec(k0s+1,:) + (1-eta)*loudSpec(k0s,:); % linear interp
    f0s = f0s + val;  % Add in support to f0s from f0sc
    CCounts(kc) = CCounts(kc) + 1;
    f0sc = f0sc + f0; % Up to next harmonic
  end
  myChroma(kc,:) = f0s/CCounts(kc); % support for f0 for all time
  if doPlot>1
    figure('position',figPos);
    plot(tMGB,f0s);
    title(sprintf('F0 = %d support over time',f0sc));
    if doPause
      disp('PAUSING'); pause;
    end
  end
  kc = kc+1; % Up we go to the next semitone (or fraction thereof)
  f0 = f0 * 2^(1/(binsPerSemitone*12));  % Advance to next spectral sample
end

% Plotting
if doPlot
  [pitches_M,pitches_m] = getPitches(fmin);
  figure('position',figPos);
  mesh(myChroma);
  title('Chroma');
  if doPause
    disp('PAUSING'); pause;
  end

  figure('position',figPos);
  subplot(2,1,1);
  stem([1:binsPerSemitone*12*octaves],myChroma); grid('on'); % overlay plot
  title('Chromagram Overlay over All Time');
  xlabel(['Pitch Class from ',pitches_M(1)]);
  set(gca,'XTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'XTickLabel',pitches_M);
  ylabel('Spectral Support');

  subplot(2,1,2);
  imagesc(myChroma);
  title(sprintf('Chromagram - imagesc'));
  set(gca,'YTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'YTickLabel',pitches_M);
  ylabel('pitch class');
  set(gca,'YDir','normal');

  if doPause, disp('PAUSING'); pause; end
end
