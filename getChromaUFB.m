% function myChroma = getChromaUFB(loudSpec,tUFB,fUFB,fmin,fmax,binsPerSemitone,octaves,doPlot,doPause);
% Form Chromagram from a Uniform Filter-Bank (UFB) output
Nt = length(tUFB);
Nf = length(fUFB);
binsPerOctave = 12*binsPerSemitone;
Nc = binsPerOctave*octaves; % number of chroma samples
myChroma = zeros(Nc,Nt);

% Traverse frequency samples (binsPerSemitone*12 samples per octave)
% starting at fmin, summing all f0-support for that frequency.

f0 = fmin;
f0scMax = fmax;

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner
  figure('position',figPos);
end

for n=1:Nt
  for kc=1:Nc
    f0 = fmin * 2^((kc-1)/binsPerOctave);
    f0s = 0; % Support for f0 in the spectrogram, current frame
    f0sc = f0; % f0 support frequency starts with f0
    k0sLast = 1; % for optimization
    while f0sc < f0scMax
      k0s = findIndexBelow(fUFB,f0sc,k0sLast); % defined below
      k0sLast = k0s; % search search here next time
      eta = (f0sc-fUFB(k0s))/(fUFB(k0s+1)-fUFB(k0s)); % interpolation constant
      val = eta * loudSpec(k0s+1,n) + (1-eta)*loudSpec(k0s,n); % linear interp
      % I think the following can probably be vectorized to that the loop over
      % frames can go away:
      if val>f0s, f0s=val; else f0s=f0s+val; end % add support after max support appears
      f0sc = f0sc + f0; % Up to next harmonic
    end
    myChroma(kc,n) = f0s; % support for f0 - may need to normalize by number of harmonics in search range
    if doPlot > 1
      plot(tUFB,f0s);
      title(sprintf('F0 = %d support over time',f0));
      if doPause, disp('PAUSING'); pause; end
      mesh(myChroma);
      title(sprintf('myChroma for kc = %d, frame %d',kc,n));
      if doPause, disp('PAUSING'); pause; end
    end
  end
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
