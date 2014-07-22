% Chord Recognition Project @ CCRMA 2014
% Sub module 2: Chromagram Formation
% desc: To form a chromagram based on the loudness spectrogram

%! function Chromagram = getBeatChroma(loudSpec,beats_in_frames,fmin,octaves,binsPerSemitone,nocts,medSmooth,doPlot,doPause)

% inputs: 
%        loudSpec -- loudness spectrogram (e.g., A-weighted dB)
%        beats_in_frames -- beat times in frames, computed by beat()
%        fmin     -- frequency of first bin (Hz)
%        binsPerSemitone -- number of bins per semitone
%        nocts    -- number of octaves we are looking at
%        medSmooth -- length of median smoother as a FRACTION OF ONE BEAT
%        octaves  -- number of octaves for chroma to be defined (1 normal)
%        doPlot   -- boolean, plot or not
%        doPause  -- boolean, pause after each plot or not
% output:
%        Chromagram -- The chromagram after moving median filter

% Sum the loudness spectrogram into a single octave
if mod(nocts,octaves) ~= 0
  error('getBeatChroma.m: Figure out what to do when octaves does not divide nocts');
end

% beat-synchronous chromagram (using labrosa's beat tracker)
beatSpec = ones(size(loudSpec))*min(min(loudSpec));
% Get the beat-sync spectrum
for t = 1:length(beats_in_frames)-1
    curr_beat = round(beats_in_frames(t));              % Get prev beat time (in frame)
    next_beat = round(beats_in_frames(t+1)) - 1;        % Get next beat time
    if curr_beat < 1, curr_beat = 1; end
    if next_beat < 1, next_beat = 1; end
    
    if curr_beat > nFrames, curr_beat = nFrames; end
    if next_beat > nFrames, next_beat = nFrames; end
    
    if next_beat < curr_beat+1
      next_beat = curr_beat+1;
    end

    spec_seg = loudSpec(:,curr_beat+1:next_beat); % Get corresponding spectrogram segment
    % medSpec = median(spec_seg,2);
    medSpec = mean(spec_seg,2);
    % beatSpec(:,curr_beat:next_beat) = repmat(median(spec_seg,2),1,size(curr_beat:next_beat,2));
    beatSpec(:,curr_beat:next_beat) = repmat(medSpec,...
                                             1,size(curr_beat:next_beat,2));
end
beatSpec(:,next_beat+1:end) = loudSpec(:,next_beat+1:end);
beatChromagram = kron(ones(1,nocts/octaves),eye(binsPerSemitone*12*octaves)) * beatSpec;

% beatChromagram = zeros(size(Chromagram));  
% % Get the beat-sync spectrum
% for t = 1:length(b)-1
%     curr_beat = round( beats_in_frames(t));              % Get prev beat time (in frame)
%     next_beat = round( beats_in_frames(t+1)) - 1;        % Get next beat time
%     if curr_beat < 1, curr_beat = 1; end
%     if next_beat < 1, next_beat = 1; end
%     chroma_seg = Chromagram(:,curr_beat:next_beat); % Get corresponding spectrogram segment
%     beatChromagram(:,curr_beat:next_beat) = repmat(median(chroma_seg,2),1,size(curr_beat:next_beat,2));
% end
% beatChromagram(:,next_beat+1:end) = Chromagram(:,next_beat+1:end);

% median filtering preserves discontinuities, so it should be ok after beat-synching:

beatDurFrames = mean(diff(beats_in_frames));
beatDur = beatDurFrames*R/fs;
winL = round(medSmooth*beatDurFrames);
if medSmooth>0
  if winL>0 && mod(winL,2)==0, winL=winL+1; end; % want odd
  disp(sprintf('Average beat duration = %0.3f sec',beatDur));
  disp(sprintf('Median smoother = %0.1f beat = %0.3f sec = %d frames',medSmooth,medSmooth*beatDur,winL));
  Chromagram = chromaFilter(beatChromagram,binsPerSemitone*12,winL);
else
  Chromagram = beatChromagram;
end

% Plotting

[pitches_M,pitches_m] = getPitches(fmin);

%chord24 = [pitches_M;pitches_m];
%M = size(beatChromagram,2);               %M: number of frames
%interp = 100;

% Plot chromagram

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner

  % figure('position',figPos);
  % stem([1:binsPerSemitone*12*octaves],beatChromagram); % overlay plot
  % xlabel(['Pitch Class from ',pitches_M(1)]);
  % ylabel('Spectral Support');
  % title('beatChromagrams before filtering');
  % if doPause, disp('PAUSING'); pause; end

  figure('position',figPos);
  mesh(Chromagram);
  xlabel('Time (frames)');
  ylabel('Note');
  set(gca,'YTickLabel',pitches_M);
  zlabel('Spectral Support');
  title(sprintf('Beat-Synchronized, Median-Filtered(%d-frames) Chromagrams through Time',winL));
  set(gca,'YTick',1:binsPerSemitone:binsPerSemitone*12);
  set(gca,'YTickLabel',pitches_M);
  if doPause, disp('PAUSING'); pause; end

if 0
  figure('position',figPos);
  subplot(2,2,[1 2]);
  imagesc(chroma);
  title('beatChromagram before filtering');
  set(gca,'YTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'YTickLabel',pitches_M);
  ylabel('pitch class');
  set(gca,'YDir','normal');
  set(gca,'XTick',1:100:M-1);  %Set: show a number every 100 numbers
  secs = ((1:100:nFrames)-1) * R/fs; %Convert X axis from frame to time
  set(gca,'XTickLabel',num2str(round(secs(:)))); %Round to seconds
  xlabel('Time (s)');
end
  
  figure('position',figPos);
  imagesc(Chromagram);
  hold('on');
  for t=1:length(beats_in_frames)
    x = beats_in_frames(t);
    plot([x x],[1 12],'-k','linewidth',1); % mark beats on chromagram
  end
  title(sprintf('Beat-Synchronized, Median-Filtered(%d-frames) Chromagrams through Time',winL));
  set(gca,'YTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'YTickLabel',pitches_M);
  ylabel('pitch class');
  set(gca,'YDir','normal');
  set(gca,'XTick',1:100:nFrames-1); %Set: show a number every 100 numbers
  secs = ((1:100:nFrames)-1) * R/fs; %Convert X axis from frame to time
  set(gca,'XTickLabel',num2str(round(secs(:))));                  %Round to seconds
  xlabel('Time (s)');
  if doPause, disp('PAUSING'); pause; end
  hold('off');
  
  figure('position',figPos);
  imagesc(beatChromagram);
  title(sprintf('beatChromagram before median filtering across frames of order %d',winL));
  set(gca,'YTick',1:round(binsPerSemitone):binsPerSemitone*12*octaves);
  set(gca,'YTickLabel',pitches_M);
  ylabel('pitch class');
  set(gca,'YDir','normal');
  set(gca,'XTick',1:100:nFrames-1); %Set: show a number every 100 numbers
  secs = ((1:100:nFrames)-1) * R/fs; %Convert X axis from frame to time
  set(gca,'XTickLabel',num2str(round(secs(:))));                  %Round to seconds
  xlabel('Time (s)');
  if doPause, disp('PAUSING'); pause; end

end
