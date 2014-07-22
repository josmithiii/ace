% Chord Recognition Project @ CCRMA 2014
% function ACE
% desc: Automatic Chord Estimation - the main function

isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
  setenv('GNUTERM','aqua')
  graphics_toolkit('fltk');
end

% Cannot clear when debugging since pending breakpoints will be cleared:
% clear all; close all;
% clearall; % to clear manually
clear wavenameroot; % Must clear for logic below to work
if isOctave
  debug_on_error();
end
% dbstop("gene_loop_specgram_6",1)

wavdir = './wav/';     % directory of .wav audio files ../wav/
wavdsdir = './wavds/'; % directory of DOWNSAMPLED .wav audio files
labdir = './lab/';     % *.lab "ground truth" chord-label files

% Specify a single-file test if desired here.
% If wavenameroot is not set, all files in wavdir will be processed:
wavenameroot = 'fps1'; % electric piano chords + bass & drums
%wavenameroot = 'chord';   % see ./makeChord.m
%wavenameroot = 'chord1';  % chord of sine tones
%wavenameroot = 'chord10'; % chord of bandlimited sawtooths
% Note that 44100 = 2^2 * 3^2 * 5^2 * 7^2:
%fs = 44100/5; % Analysis sampling rate (should divide original rate)
%fs = 44100/10; % Kitty's original decimation factor
fs = 44100/6; % Too low for MGB
%fs = 16000;   % LabRosa's rate (most common rate in speech recognition)
fmin = 65.4;  % Kitty's original lower limit
% fmin = 41.2; % Low E on the bass guitar (was 65.4)
% fmin = 440;  % Sufficient for 'chord*' tests
% fmin = 1000; % simple more visible test
%binsPerSemitone = 3; % Kitty's original sampling density
binsPerSemitone = 1;
octaves = 1;    % number of octaves spanned by chroma (normally 1)
constantQ = 1;
cgsThreshDB = 100; % chromagram silence threshold (below max) in dB
doClass = 1;   % enable preliminary classification
doLabWrite=1;  % enable writing of ACE .lab file alongside ground-truth file
doPlot = 0;    % plot or not
doPause = 0;   % pause after each plot
debugSpec = 0; % toggle plotting and pausing in getSpec
doPrint = 0;   % print detailed final results (each time frame) to console
doBeat = 0;    % Beat-Synchronuous Chromagram (need to be fixed)
if doBeat
  medSmooth = 0; % Length of median smoother in BEATS
else
  % Median smoother length is now in SECONDS
  % medSmooth = 0; % comparison basis
  medSmooth = 1.6714; % gives 13 frames when fs=7350 and R=945
  % medSmooth = 1.2; % gives 13 frames when fs=44100 and R=4096
  % Cho & Bello's study determined 13 frames was best.
  % We believe their hop size was 4096 (93 ms) at a 44100 Hz sample rate,
  % so 13 frames would span 13*4096/44100 = 1.2 sec.
  % HOWEVER, we observed that 1.6714 sec performs slightly better.
end
minLoudnessModel = 0; % 0 or higher
maxLoudnessModel = 5;
  loudnessModelSqrtMag = 0;
  loudnessModelMag = 1;
  loudnessModelMagSq = 2;
  loudnessModelDB = 3;
  loudnessModelAWeightedDB = 4;
  loudnessModelGaussWeightedMag = 5;
  loudnessModelMGB = 6;

screensize = get(0,'screensize');
figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner

[status,hostname] = system('hostname');
disp(sprintf('ACE on %s',hostname));
disp(sprintf('fs = %d',fs));
disp(sprintf('fmin = %0.1f',fmin));
disp(sprintf('binsPerSemitone = %d',binsPerSemitone));
disp(sprintf('medSmooth = %0.3f sec',medSmooth));
disp(sprintf('doClass = %d, constantQ = %d, doBeat = %d', doClass,constantQ,doBeat));

if exist('wavenameroot')==1
  disp(sprintf('Doing single-file test of %s',wavenameroot));
  wavenameroots = {wavenameroot};
else
  allfiles = dir(wavdir);
  wavenameroots = cell(length(allfiles)-2); % . and .. are in there
  windex=0;
  for i = 1:size(allfiles)
    filename = allfiles(i).name;
    if filename(end) == 'v'; % If it's a wave file
      windex=windex+1;
      wavenameroots(windex) = cellstr(filename(1:end-4));
    end
  end
  wavenameroots = wavenameroots(1:windex)
  disp('more off');
  more('off');
end

% Set up evaluation results file ACE-eval.csv
logfiledir = 'RESULTS';
logfileroot = 'ACE-eval';
fid = openLogFile(logfiledir,logfileroot,'csv');
fidLT = openLogFile(logfiledir,logfileroot,'tex');
maxwnrlen=51;
fprintf(fid,'%% ACE on %s\n',hostname);
fprintf(fid,'%% fs = %d\n',fs);
fprintf(fid,'%% fmin = %0.1f\n',fmin);
fprintf(fid,'%% binsPerSemitone = %d\n',binsPerSemitone);
fprintf(fid,'%% doClass = %i, constantQ = %i\n\n', doClass,constantQ);

fprintf(fid,'%% Each column below has two entries, one for 24 chords and the other for 48 chords\n');

fprintf(fid,'song\t');
%fprintf(fid,'\t');

fprintf(fid,'0 - sqrt(mag)\t');
%fprintf(fid,'\t');

fprintf(fid,'1 - mag\t');
%fprintf(fid,'\t');

fprintf(fid,'2 - mag^2\t');
%fprintf(fid,'\t');

fprintf(fid,'3 - dB\t');
%fprintf(fid,'\t');

fprintf(fid,'4 - dB-A\t');
%fprintf(fid,'\t');

fprintf(fid,'5 - dB-G\t');
%fprintf(fid,'\t');

if maxLoudnessModel>=loudnessModelMGB
  fprintf(fid,'6 - MGB\t');
  %fprintf(fid,'\t');
end
fprintf(fid,'\n');

% Storing total accuracy score for calculating average
total_frames = 0;
NLModels = maxLoudnessModel+1;
totalScore24 = zeros(NLModels,1);
totalScore48 = zeros(NLModels,1);
totalCoincidence24 = zeros(NLModels,1);
totalCoincidence48 = zeros(NLModels,1);

nFiles = length(wavenameroots);
fileDursSamps = zeros(1,nFiles);

tic;
for iwnr = 1:nFiles  % Loop over all wav files
  wavenameroot = wavenameroots{iwnr};
  disp('================================================================');
  disp(wavenameroot);
  disp('---');
  fprintf(fid,wavenameroot);
  fprintf(fid,'\t');
  wnrlen = length(wavenameroot);
  if wnrlen>maxwnrlen
    wavenamerootLT = [wavenameroot(1:maxwnrlen),'...'];
  else
    wavenamerootLT = wavenameroot;
  end
  wavenamerootLT = strrep(wavenameroot,'_','\\_');
  labpath = [labdir,wavenameroot,'.lab'];
  if exist(labpath) == 2
    fprintf(fidLT,wavenamerootLT);
    fprintf(fidLT,' & ');
  end
  if isOctave, fflush(stdout); end
  wave = getWave(wavenameroot,fs,wavdir,wavdsdir); % load wave file ./getWave.m
  fileDursSamps(iwnr) = length(wave);

  %% Step 1: magnitude-squared spectrogram of wave
  % getSpec; % call as a script to leave all vars in global scope (comment out function line)
  ds = debugSpec;
  [mySpec,fc,nocts,M,R]=getSpec(wave,fs,constantQ,fmin,binsPerSemitone,doPlot*ds,doPause*ds); % ./getSpec.m
                                                                                              % getSpec; % ./getSpec.m
  windowLength = M; % protect variable
  if isOctave, fflush(stdout); end

  if doBeat
    if ~(exist('beat') == 2)
      addpath('./coversongs/','-begin');
      if ~(exist('beat') == 2)
        error('Unpack labrosa-coversongid.tgz in the ACE directory to create ./coversongs/*');
      end
    end
    beats_in_secs = beat(wave,fs);        % Get beat times in secs
    beats_in_frames = beats_in_secs*fs/R; % Convert beat times to frames
  end

  % Loop over loudness models:
  for loudnessModel = minLoudnessModel:maxLoudnessModel

    disp('---');
    disp(sprintf('constantQ = %d',constantQ));

    % Convert magnitude-squared spectrogram to loudness spectrogram: ./getLoudSpec.m

    %[loudSpec,tMGB,fMGB] = getLoudness(loudnessModel,wave,mySpec,fc,R,fs,doPlot,doPause);
    if loudnessModel==loudnessModelMGB, nargout=3; else nargout=1; end
    nargin=8; getLoudness; nargout=0;

    [nFreqs,nFrames] = size(loudSpec);
    if (loudnessModel==minLoudnessModel)
      total_frames = total_frames + nFrames; % do this only once per song
      nFrames1 = nFrames;
    else
      if nFrames ~= nFrames1
        error('ACE.m: Code presently assumes nFrames the same for all loudness models');
      end
    end
    if doPlot
      % Plot the loudness spectrogram for interactive perusal:
      figurepos(figPos);
      times = [0:nFrames-1] * R / fs; % frame-begin times
      times = times + 0.5 * R / fs;   % frame-center times
      mesh(times,fc,loudSpec);
      title(sprintf('ACE: Spectrogram for loudnessModel %d',loudnessModel));
      if doBeat
        set(gca,'XTick',beats_in_secs); % Mark beat times
      end
      xlabel('Time (s)');
      ylabel('Frequency (Hz)');
      % zlabel('Magnitude (A-Weighted dB)');
      if doPause, disp('PAUSING'); pause; end
      hold('off');
    end

    % clipping at -100 dB and  0.5 to get 10*log10 for dB(power)

    %% Step 2: Chromagram Formation: ./getChroma.m
    if loudnessModel==loudnessModelMGB % MGB
                                       % myChroma = getChromaMGB(loudSpec,tMGB,fMGB,fmin,binsPerSemitone,octaves,doPlot,doPause); % ./getChromaMGB.m
      nargin=7;
      getChromaMGB; % computes myChroma % ./getChromaMGB.m
    else
      if constantQ
        if doBeat
          %!    myChroma = getBeatChroma(loudSpec,beats_in_frames,fmin,binsPerSemitone*12,nocts,medSmooth,octaves,doPlot,doPause);
          getBeatChroma; % ./getBeatChroma.m
          myChroma = beatChromagram;
        else
          %!    myChroma = getChroma(loudSpec,fmin,binsPerSemitone*12,nocts,medSmooth,octaves,doPlot,doPause);
          getChroma; myChroma = Chromagram; % ./getChroma.m
        end
      else
        nargin=7;
        tUFB = [0:nFrames-1] * R / fs; % frame-begin times
        tUFB = tUFB + 0.5 * R / fs;   % frame-center times
        fUFB = fc; % frequences
        getChromaUFB; % computes myChroma % ./getChromaUFB.m
      end
    end

    %% Step 2.1: Classify silence/noise/chord/other/bloops
    if (loudnessModel==loudnessModelDB) ...
          || (loudnessModel==loudnessModelAWeightedDB)
      cgsThresh = cgsThreshDB;
    elseif (loudnessModel==loudnessModelGaussWeightedMag)
      cgsThresh = 10^(cgsThreshDB/20);
    elseif (loudnessModel==loudnessModelMagSq)
      cgsThresh = 10^(cgsThreshDB/10);
    elseif (loudnessModel==loudnessModelMag)
      cgsThresh = 10^(cgsThreshDB/20);
    elseif (loudnessModel==loudnessModelSqrtMag)
      cgsThresh = sqrt(10^(cgsThreshDB/20));
    else
      error('Unknown loudness model');
    end

    if doClass
      %! class = getClass(myChroma,cgsThresh);
      getClass;
    else
      class=1; % pretend everything is some chord at all times
    end

    for numchords = [24,48]
      disp(sprintf('%d chords',numchords));
      Template = buildTemplate(fmin,binsPerSemitone*12,numchords,0,0);
      % buildTemplate; % ./buildTemplate.m

      %% Step 4: Chord Estimation:
      [myChord Fitness_Matrix] = chordEstimate(myChroma,class,fmin,numchords,Template,doPlot,doPause);
      % chordEstimate; % ./chordEstimate.m

      %% Step 5: Evaluation and Comparison to Ground Truth

      if exist(labpath) == 2
        [ground_truth, start_t, end_t, ~] = loadGroundTruthChrisHarte(labpath,numchords,0); 
        % loadGroundTruth; % ./loadGroundTruth.m
        % Note: "bassnote" doesn't work yet, so it's ignored (~) and doBass=0
        % truth = chordEvaluate(ground_truth,start_t,end_t,myChord,myChord_stat,class,M,R,fs,fmin,numchords,doPlot,doPause,doPrint)
        chordEvaluate;  % ./chordEvaluate.m
        if doLabWrite
          lwpath = [labdir,wavenameroot,sprintf('-ACE-RAW-%d.lab',numchords)];
          fidLW = fopen(lwpath,'w');
          frameTimes = (M/2 + [0:nFrames-1]*R)/fs; % sec
          if length(frameTimes) ~= length(myChord), error("ACE.m: Search for WTF"); end
          state = 'N';
          state_beg = 0;
          for m=1:length(frameTimes)
            t = frameTimes(m);
            newstate = myChord(m);
            if newstate ~=state
              state_end = t;
              if state_end ~= state_beg
                state = myChord(m);
                fprintf(fidLW,"%.6f %.6f %s\n",state_beg,state_end,chordNumToSymbol(state,numchords,fmin));
                state = newstate;
                state_beg = state_end; % start next
              end
            end
          end
          fclose(fidLW);
          %---
        end
        if isOctave, fflush(stdout); end
        fprintf(fid,'%s\t',num2str(finalScore));
        lmp1 = loudnessModel+1;
        if numchords == 24
          totalScore24(lmp1) = totalScore24(lmp1)+finalScore;
          totalCoincidence24(lmp1) = totalCoincidence24(lmp1)+sum(coincidence);
        elseif numchords == 48
          totalScore48(lmp1) = totalScore48(lmp1)+finalScore;
          totalCoincidence48(lmp1) = totalCoincidence48(lmp1)+sum(coincidence);
        else
          error(sprintf('%d chords not supported'),numchords);
        end
        if loudnessModel == maxLoudnessModel && numchords == 48
          fprintf(fidLT,'%0.1f \\\\',finalScore);
        else
          fprintf(fidLT,'%0.1f & ',finalScore);
        end
      else
        disp(sprintf('NEED %s (GROUND TRUTH) FOR COMPARISON/EVAL',labpath));
      end
    end % loop over numchords
  end % loop over loudness models
  fprintf(fid,'\n');
  fprintf(fidLT,'\n');
end % loop over wav files
elapsed_time = toc; % elapsed time over all wav files
disp(sprintf('Total elapsed time = %0.3f seconds',elapsed_time));
tmt_samps = sum(fileDursSamps);
tmt_secs = tmt_samps/fs;
disp(sprintf('Total music time = %0.3f seconds = %d samples',tmt_secs,tmt_samps));
rtratio = tmt_secs/elapsed_time;
disp(sprintf('On host %s, running at = %0.2f times real time at sampling rate %d Hz',...
             hostname(1:end-1),rtratio,fs));
fprintf(fid,'%% Real-time ratio = %0.2f\n',rtratio);

% Calculate averages
averageScore24 = totalScore24 / length(wavenameroots);
averageScore48 = totalScore48 / length(wavenameroots);

% calculate weight average CSR = total_coincidence/total_frames
weightScore24 = 100*totalCoincidence24 / total_frames;
weightScore48 = 100*totalCoincidence48 / total_frames;

% --------------------------------------------------------------------------
% First, print everything to the terminal, then the log files:

disp(sprintf('\n\nAverage Accuracy\n'));

disp('24 chords:');
n=1;
disp(sprintf('Sqrt(Magnitude)          : %0.2f ',averageScore24(n))); n=n+1;
disp(sprintf('Magnitude                : %0.2f ',averageScore24(n))); n=n+1;
disp(sprintf('Magnitude^2              : %0.2f ',averageScore24(n))); n=n+1;
disp(sprintf('Unweighted dB            : %0.2f ',averageScore24(n))); n=n+1;
disp(sprintf('A-weighted dB            : %0.2f ',averageScore24(n))); n=n+1;
disp(sprintf('G-weighted dB            : %0.2f ',averageScore24(n))); n=n+1;

disp('');
disp('48 chords:');

n=1;
disp(sprintf('Sqrt(Magnitude)          : %0.2f ',averageScore48(n))); n=n+1;
disp(sprintf('Magnitude                : %0.2f ',averageScore48(n))); n=n+1;
disp(sprintf('Magnitude^2              : %0.2f ',averageScore48(n))); n=n+1;
disp(sprintf('Unweighted dB            : %0.2f ',averageScore48(n))); n=n+1;
disp(sprintf('A-weighted dB            : %0.2f ',averageScore48(n))); n=n+1;
disp(sprintf('G-weighted dB            : %0.2f ',averageScore48(n))); n=n+1;

disp(sprintf('\n\nCSR Chord Symbol Recall\n'));

disp('24 chords:');
n=1;
disp(sprintf('Sqrt(Magnitude)          : %0.2f ',weightScore24(n))); n=n+1;
disp(sprintf('Magnitude                : %0.2f ',weightScore24(n))); n=n+1;
disp(sprintf('Magnitude^2              : %0.2f ',weightScore24(n))); n=n+1;
disp(sprintf('Unweighted dB            : %0.2f ',weightScore24(n))); n=n+1;
disp(sprintf('A-weighted dB            : %0.2f ',weightScore24(n))); n=n+1;
disp(sprintf('G-weighted dB            : %0.2f ',weightScore24(n))); n=n+1;

disp('');
disp('48 chords:');
n=1;
disp(sprintf('Sqrt(Magnitude)          : %0.2f ',weightScore48(n))); n=n+1;
disp(sprintf('Magnitude                : %0.2f ',weightScore48(n))); n=n+1;
disp(sprintf('Magnitude^2              : %0.2f ',weightScore48(n))); n=n+1;
disp(sprintf('Unweighted dB            : %0.2f ',weightScore48(n))); n=n+1;
disp(sprintf('A-weighted dB            : %0.2f ',weightScore48(n))); n=n+1;
disp(sprintf('G-weighted dB            : %0.2f ',weightScore48(n))); n=n+1;

% ----------------------------------------------------
% Print results to log files:

fprintf(fid,'\nAverage Accuracy for 24 chords:\t');
fprintf(fidLT,'\n%% Average Accuracy for 24 chords:\n');
[sass,saskey] = sort(averageScore24);
winner = saskey(end); % index of largest average score
for i = 1:length(averageScore24)
  fprintf(fid,'%s\t',num2str(averageScore24(i)));
  if i==winner
    sstr = sprintf('\\textbf{%0.1f}',averageScore24(i));
  else
    sstr = sprintf('%0.1f',averageScore24(i));
  end
  if i == length(averageScore24)
    fprintf(fidLT,'%s\\\\',sstr);
  else
    fprintf(fidLT,'%s & ',sstr);
  end
end
fprintf(fid,'\n');
fprintf(fidLT,'\n');

% ------------------------
fprintf(fid,'Average Accuracy for 48 chords:\t');
fprintf(fidLT,'%% Average Accuracy for 48 chords:\n');
[sass,saskey] = sort(averageScore48);
winner = saskey(end); % index of largest average score
for i = 1:length(averageScore48)
  fprintf(fid,'%s\t',num2str(averageScore48(i)));
  if i==winner
    sstr = sprintf('\\textbf{%0.1f}',averageScore48(i));
  else
    sstr = sprintf('%0.1f',averageScore48(i));
  end
  if i == length(averageScore48)
    fprintf(fidLT,'%s\\\\',sstr);
  else
    fprintf(fidLT,'%s & ',sstr);
  end
end
fprintf(fid,'\n');
fprintf(fidLT,'\n');

% ------------------------

fprintf(fid,'\nCSR Chord Symbol Recall:\n');

fprintf(fid,'\n24 chords:\n');
n=1;
fprintf(fid,'Sqrt(Magnitude)          : %0.2f\n',weightScore24(n)); n=n+1;
fprintf(fid,'Magnitude                : %0.2f\n',weightScore24(n)); n=n+1;
fprintf(fid,'Magnitude^2              : %0.2f\n',weightScore24(n)); n=n+1;
fprintf(fid,'Unweighted dB            : %0.2f\n',weightScore24(n)); n=n+1;
fprintf(fid,'A-weighted dB            : %0.2f\n',weightScore24(n)); n=n+1;
fprintf(fid,'G-weighted dB            : %0.2f\n',weightScore24(n)); n=n+1;

% ----------

disp('');
fprintf(fid,'\n48 chords:\n');
n=1;
fprintf(fid,'Sqrt(Magnitude)          : %0.2f\n',weightScore48(n)); n=n+1;
fprintf(fid,'Magnitude                : %0.2f\n',weightScore48(n)); n=n+1;
fprintf(fid,'Magnitude^2              : %0.2f\n',weightScore48(n)); n=n+1;
fprintf(fid,'Unweighted dB            : %0.2f\n',weightScore48(n)); n=n+1;
fprintf(fid,'A-weighted dB            : %0.2f\n',weightScore48(n)); n=n+1;
fprintf(fid,'G-weighted dB            : %0.2f\n',weightScore48(n)); n=n+1;

% ----------------------------------------------------

fprintf(fidLT,'\n\n%% CSR Chord Symbol Recall');

fprintf(fidLT,'\n\n%% 24 chords, raw scores:\n');
n=1;
fprintf(fidLT,'%0.1f & ',weightScore24(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore24(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore24(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore24(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore24(n)); n=n+1;
fprintf(fidLT,'%0.1f \\\\ ',weightScore24(n));

disp('');
fprintf(fidLT,'\n\n%% 48 chords, raw scores:\n');
n=1;
fprintf(fidLT,'%0.1f & ',weightScore48(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore48(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore48(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore48(n)); n=n+1;
fprintf(fidLT,'%0.1f & ',weightScore48(n)); n=n+1;
fprintf(fidLT,'%0.1f \\\\ ',weightScore48(n));

fclose(fid);
fclose(fidLT);
