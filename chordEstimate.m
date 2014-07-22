% Chord Recognition Project @ CCRMA 2014
% Sub module 5: Chord Estimation
% desc: A basic chord estimation based on the fitness matrix

function [myChord Fitness_Matrix] = chordEstimate(myChroma,class,fmin,numchords,Template,doPlot,doPause)

% function: chordEstimate(Template,doPlot,doPause)
% input:   myChroma - the chromagram
%          class    - chromagram classification versus time: '1=chord','2=silence','3=noise'
%          Template - binary chord template
%          doPlot   - boolean, plot or not
%          doPause  - boolean, pause after each plot or not
% output:  myChord  - my estimated chords
%          FitnessMatrix - The fitness matrix

% Note from Kitty: I've implemented two ways, one is by using the dot product,
%   Another way is to use the Euclidean distance. I think they're pretty 
%   much the same thing. But maybe we can test if we have time?

%% Create Fitness Matrix
% Calculating dot product of numChords Template * Chromagram 
% Templates: numchords * bpo
% Chromagram: bpo * frames = 12 * 1889
if 0
  upperChroma = ones(size(myChroma))*mean(mean(myChroma));
  nKeep = 12;
  [nC,nF] = size(myChroma);
  for f=1:nF
    [sc,k] = sort(myChroma(:,f));
    sk = k(end-nKeep+1:end);
    upperChroma(sk,f) = myChroma(sk,f);
  end
else
  upperChroma = myChroma;
end
Fitness_Matrix = Template * upperChroma;

% Class = 
% 1 for chord
% 2 for silence
% 3 for noise
nClass = length(class);
fmMin = min(min(Fitness_Matrix));
for m=1:nClass
  if class(m) ~= 1
    Fitness_Matrix(:,m) = fmMin; % make silence/noise 0
  end
end

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner
  figurepos(figPos);
  % Plot the fitness matrix for interactive perusal:
  if size(Fitness_Matrix,2)>2
    mesh(Fitness_Matrix);
  else
    plot(Fitness_Matrix);
  end
  title('Fitness Matrix = TemplateMatrix * Chromagram = Chord Scores vs Time');
  xlabel('Time (frames)');
  ylabel('Major-Minor Chord Index');
  zlabel('Magnitude (Measure of Fit)');
  if doPause, disp('PAUSING'); pause; end
end

% Option 1: Pick up the template that maximize dot product
[~, myChord] = max(Fitness_Matrix);

%% Option 2: Calculating Euclidean Distance: See below      
% Create Distance Matrix, find my chord sequence: mypath

% Calculate Euclidean Distance
% Creating a Distance Matrix of size 24 * num_of_frames
% such that D(x,y) represents the Euclidean Distance
% between Template(x,:) and Chroma_Matrix(:,y)
% Need to flip Chroma_Matrix (from 36*frame to frame*36)
% (between each frame of chroma matrix and each column in Template Matrix)
% code reference: "Matlab array manipulation tips and tricks" 10.4  (Acklam)

%         X = Template;                                         % Size: numchords * 36;
%         Y = chroma_smooth';                                   % Size: frame * 36;
%         m = 24;     n = frameM;                               % define m,n 
%         Distance_Matrix = sqrt(sum(abs(	repmat(permute(X, [1 3 2]), [1 n 1]) ... 
%                         - repmat(permute(Y, [3 1 2]), [m 1 1]) ).^2, 3));
%         

% Calculate the template that has the minimum distance for each frame
% [~, myChord] = min(Distance_Matrix);
% size(Fitness_Matrix)

%% Plot

if doPlot

  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner
  figurepos(figPos);

  [pitches_M, pitches_m, pitches_M7, pitches_m7] = getPitches(fmin);
  if numchords == 24,
    chordn = [pitches_M;pitches_m; 'N  '];
  elseif numchords == 48,
    chordn = [pitches_M; pitches_m; pitches_M7; pitches_m7; 'N  '];
  end;
  M = size(Fitness_Matrix,2);               %M: number of frames
  
  
  % Plot the Fitness Matrix
  imagesc(Fitness_Matrix); grid('on');
  hold on;
  plot(myChord,'-*k','linewidth',3);  % Overlay estimated chord
  title('Fitness Matrix = TemplateMatrix * Chromagram = Chord Scores vs Time');
  set(gca,'YDir','normal');
  set(gca,'YTick',1:numchords+1);
  %set(gca,'YTick',1:numchords);
  set(gca,'YTickLabel',chordn);
  % set(gca,'XTick',1:100:M-1);
  % secs = ((1:100:M)-1) * R/fs;
  % set(gca,'XTickLabel',num2str(round(secs')));        %Round to seconds
  % xlabel('Time (s)');
  xlabel('Time (frames)');
  if doPause, disp('PAUSING'); pause; end
  hold off
end
