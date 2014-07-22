% Chord Recognition Project @ CCRMA 2014
% Sub module 2: Chromagram Formation
% desc: To form a chromagram based on the loudness spectrogram

%! function Chromagram = getChroma(loudSpec,fmin,octaves,binsPerSemitone,nocts,medSmooth,doPlot,doPause)

% inputs: 
%        loudSpec -- loudness spectrogram (e.g., A-weighted dB)
%        fmin     -- frequency of first bin (Hz)
%        binsPerSemitone -- number of bins per semitone
%        nocts    -- number of octaves we are looking at
%        medSmooth -- length of median smoother in SECONDS
%        octaves  -- number of octaves for chroma to be defined (1 normal)
%        doPlot   -- boolean, plot or not
%        doPause  -- boolean, pause after each plot or not
% output:
%        Chromagram -- The chromagram after moving median filter

% Sum the loudness spectrogram into a single octave
if mod(nocts,octaves) ~= 0
  error('getChroma.m: Figure out what to do when octaves does not divide nocts');
end
chroma = kron(ones(1,nocts/octaves),eye(binsPerSemitone*12*octaves)) * loudSpec;

winL = round(medSmooth*fs/R);
if winL>0 && mod(winL,2)==0, winL=winL+1; end; % want odd
disp(sprintf('Median smoother = %0.3f sec = %d frames',medSmooth,winL));

% pre-filtering - moving median
if winL>0
  Chromagram = chromaFilter(chroma,binsPerSemitone*12,winL);
else
  Chromagram = chroma;
end

% Plotting
[pitches_M,pitches_m] = getPitches(fmin);

%chord24 = [pitches_M;pitches_m];
%M = size(Chromagram,2);               %M: number of frames
%interp = 100;

% Plot chromagram before filtering

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner

  % figure('position',figPos);
  % stem([1:binsPerSemitone*12*octaves],Chromagram); % overlay plot
  % xlabel(['Pitch Class from ',pitches_M(1)]);
  % ylabel('Spectral Support');
  % title('Chromagrams before filtering');
  % if doPause, disp('PAUSING'); pause; end

  figure('position',figPos);
  mesh(Chromagram);
  xlabel('Time (frames)');
  ylabel('Note');
  set(gca,'YTickLabel',pitches_M);
  zlabel('Spectral Support');
  title('Chromagrams through Time');
  set(gca,'YTick',1:binsPerSemitone:binsPerSemitone*12);
  set(gca,'YTickLabel',pitches_M);
  if doPause, disp('PAUSING'); pause; end

if 0
  figure('position',figPos);
  subplot(2,2,[1 2]);
  imagesc(chroma);
  title('Chromagram before filtering');
  set(gca,'YTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'YTickLabel',pitches_M);
  ylabel('pitch class');
  set(gca,'YDir','normal');
  set(gca,'XTick',1:100:M-1);  %Set: show a number every 100 numbers
  secs = ((1:100:M)-1) * R/fs; %Convert X axis from frame to time
  set(gca,'XTickLabel',num2str(round(secs(:)))); %Round to seconds
  xlabel('Time (s)');
end
  
  % Plot smoothed chromagram 
  subplot(2,2,[3 4]);
  imagesc(Chromagram);
  title(sprintf('Chromagram after median filtering across frames of order %d',winL));
  set(gca,'YTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'YTickLabel',pitches_M);
  ylabel('pitch class');
  set(gca,'YDir','normal');
  % set(gca,'XTick',1:100:M-1); %Set: show a number every 100 numbers
  % secs = ((1:100:M)-1) * R/fs; %Convert X axis from frame to time
  % set(gca,'XTickLabel',num2str(round(secs(:))));                  %Round to seconds
  % xlabel('Time (s)');
  xlabel('Time (frames)');

  if doPause, disp('PAUSING'); pause; end

end
