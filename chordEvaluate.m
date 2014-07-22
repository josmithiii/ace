% Chord Recognition Project @ CCRMA 2014
% Sub module 8: Evaluation and Comparison
% desc: This module is for ACE results evaluation

%! function [truth] = chordEvaluate(ground_truth,start_t,end_t,myChord,myChord_stat,class,M,R,fs,fmin,numchords,doPlot,doPause,doPrint)

% inputs:
%          ground_truth - ground truth chord data
%          start_t      - start time for each chord
%          end_t        - end time for each chord
%          myChord      - my estimated chords without the statistical model
%          myChord_stat - my estimated chords with the statistical model
%          class        - chromagram classification versus time: '1=chord','2=silence','3=noise'
%          M            - FFT window length used
%          R            - hop size
%          fs           - sampling rate
%          fmin         - lowest analysis frequency (Hz) (equal tempered)
%          numchords    - number of chords in the model (either 24 or 48)
% output:
%          myChord  - my chord estimate

nFrames = length(myChord); % number of chords
frameTimes = (M/2 + [0:nFrames-1]*R)/fs; % sec
truth = zeros(1,nFrames);
NT=length(ground_truth);
if (NT ~= length(start_t)) || (NT ~= length(end_t))
  error('chordEvaluate: ground_truth data malformed');
end
k0=1;
for i = 1:nFrames 
  t = frameTimes(i);
  while (t > end_t(k0)) && (k0<NT), k0=k0+1; end;
  if (start_t(k0) < t) && (t < end_t(k0))
    truth(i) = ground_truth(k0);
    if truth(i) < 1
      error(sprintf('chordEvaluate: ground_truth(%d) == %d',k0,truth(i)));
    end
  else
    truth(i) = numchords + 1; % 'N' = 'no chord' (e.g. silence)
  end
end

% Flag non-chord frames as such:
for i=1:length(class)
  if class(i) ~= 1
    myChord(i) = numchords+1;
  end
end

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner
  figurepos(figPos);
  plotData = [truth',myChord'];
  plot(frameTimes,plotData);
  tmin = frameTimes(1);
  tmax = frameTimes(end);
  axis([tmin,tmax,0,max(max(plotData))]);
  legend('truth','myChord');
  xlabel('Time (sec)');
  ylabel('Chord (index)');
end

coincidence = (truth==myChord); % Makes a "logical" type that won't plot
                                % coincidence = 1-xor(truth,myChord);
finalScore = 100*sum(coincidence)/nFrames;
disp(sprintf('Percentage correct = %0.1f for raw chord estimates',finalScore));

% Need chord names for both plotted and printed output:
[pitches_M,pitches_m,pitches_M7,pitches_m7] = getPitches(fmin);
if numchords == 24,
  chordn = [pitches_M;pitches_m; 'N  '];
elseif numchords == 48,
  chordn = [pitches_M; pitches_m; pitches_M7; pitches_m7; 'N  '];
end;

if doPlot % these plots actually take some time to produce
  figurepos(figPos);
  % 1. Plot my chord sequence without statistical model
  % subplot(2,1,1);
  % if axis ever tight: cmax = max([myChord(:);myChord_stat(:);ground_truth(:)]);
  cmax = numchords;
  axis([0 tmax 0 cmax]);
  grid('on');
  hold('on');
  title('chord sequence without Viterbi')
  rectH_true = 0.8; % Rectangle height (anything less than 1)
  rectH_est = 0.4; % Make it smaller than ground truth to see overlap
  yoff = 0.5 * (rectH_true - rectH_est); % center smaller rect vertically
  for k = 1:length(ground_truth)
    % plot([start_t(k) end_t(k)],[ground_truth(k) ground_truth(k)],'r','LineWidth',3);
    xk = start_t(k);
    yk = ground_truth(k); % y coord of rectangle base
    wk = end_t(k) - xk;
    rectangle('Position',[xk yk wk rectH_true],'FaceColor','r')
  end
  ykp = myChord(k)-1;
  for k = 1:nFrames
    yk = myChord(k);
    if yk == ykp % continue previous rectangle
      wk = wk + R/fs;
    else % start a new rectangle
      if k>1
        rectangle('Position',[xk ykp+yoff wk rectH_est],'FaceColor','k')
      end
      ykp = yk;
      xk = frameTimes(k)-0.5*R/fs;
      wk = R/fs;
    end
  end
  legend('ACE (black)','Ground Truth (red)');
  xlabel('Time (s)');
  set(gca,'YTick',1:numchords+1);
  set(gca,'YTickLabel',chordn);
  set(gca,'YDir','normal');
  ylabel('Chord');
  hold('off');
  if doPause, disp('PAUSING'); pause; end
end

if doPrint
  disp(sprintf('Time - Truth Estimate:'));
  for k = 1:nFrames
    t = frameTimes(k);
    trueChord = chordn(truth(k),:);
    estChord = chordn(myChord(k),:);
    disp(sprintf('%0.1f - %s %s',t,trueChord,estChord));
  end
end
