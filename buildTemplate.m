% Chord Recognition Project @ CCRMA 2014
% Sub module 4: Build Template
% desc: This is to build the chord template

function Template = buildTemplate(fmin,bpo,numchords,doPlot,doPause)

% inputs:
%        fmin      - frequency of first bin (Hz)
%        bpo       - number of bins per octave
%        doPlot    - boolean, plot or not
%        doPause   - boolean, pause or not
% output:
%        Template  - Chord Template

% TO-DO (Gina) : Adding seventh chord? 
% Note from Kitty: if bpo=36, then we have 36 bins per octave, not 12.
% So, for example
%  CCC C#C#C# DDD D#D#D# EEE FFF F#F#F# GGG G#G#G# AAA A#A#A# BBB 
%  111 0 0 0  000 0 0 0  111 000 0 0 0  111 0 0 0  000 0 0 0  000
%  For 1-36bin,  each 1*3    5*3     8*3    Equals 0.3   --Right
%                each 1*3-1  5*2-1   8*3-1  Equals 1     --Center 
%                each 1*3-2  5*3-2   8*3-2  Equals 0.3   --Left
%  (Add modula: plus [1:12] , mod 36)
% Then, some post Precessing with Gaussian Window for weighting  e.g C-Major 0.3 1 0.3

% no_template = 24;                                    % 12 Major + 12 Minor
% no_template = 48 + 1;          % 12 major, 12 minor, plus sevenths, plus 'N' and 'X'
if numchords ~=24 && numchords ~= 48, error('buildTemplate.m: Expected either 24 or 48 chords'); end
Template = zeros(numchords,bpo);                   % Create empty template

% Major Chords (row 1 to 12)
% Create the first row: e.g. C E G
CM = zeros(1,bpo); 
I = 1; III = 5; V = 8;               %position of I III V on keyboard
bpst = bpo/12;                       % bins per semitone (1,3,5,...)
midshift = floor(bpst/2);
% was midshift = round((1+bpst)/2);        % bpst should be odd
CM_center = [I,III,V] * bpst - midshift; % want to offset by midshift
% was CM_center = [I,III,V] * midshift; % - floor(midshift/2);    %map to bpo bin case
CM(CM_center) = 1;                   %Value at center bin
if bpst>1 
  % Each "matched filter" will be more than a single key
  % CM([CM_center-1, CM_center+1]) = 0.3; % used for bpst=3 previously
  % Note: 0.3 ~ Gaussian at 3/4 sigma => 3/2 sigma at edge
  % Note also the sampled Gaussian can be installed by the construct:
  %
  %   CM = CM * toeplitz([1,.3,zeros(1,bpo-3),.3])
  %
  % and this can be generalized to 
  %
  %   CM = CM * toeplitz([1,righthalf,zeros(1,bpo-3),lefthalf])
  %
  % where lefthalf = fliplr(righthalf) and righthalf =
  % gauss(0,1,samples_to_right_of_center_to_almost_1.5).  However, for
  % simplicity, instead of using more Gaussian samples, we'll just use a
  % uniform weighting:
  CM = CM * toeplitz([ones(1,(bpst+1)/2),zeros(1,bpo-bpst),ones(1,(bpst-1)/2)]);
end
Template(1,:) = CM;
for n = 2:12
  prev = Template(n-1,:);
  Template(n,:) = circshift(prev,[0 bpst]); % Each row circ-right-shifted
end

% Minor Chords (row 13 to 24)
% Create the first row: C bE G
cM = zeros(1,bpo); 
I = 1; bIII = 4; V = 8;                               
cM_center = [I,bIII,V] * bpst - midshift; % want to offset by midshift
cM(cM_center) = 1;
if bpst>1
  cM = cM * toeplitz([ones(1,(bpst+1)/2),zeros(1,bpo-bpst),ones(1,(bpst-1)/2)]);
  % Previously: cM([cM_center-1, cM_center+1]) = 0.3; % Sampled Gaussian distribution
end
Template(13,:) = cM;
for n = 14:24,
  prev = Template(n-1,:);
  Template(n,:) = circshift(prev,[0 bpst]);
end;

if numchords == 48, % if we use a bigger template
    % Major 7 chords (row 25 to 36)
    CM7 = zeros(1,bpo);
    I = 1; III = 5; V = 8; bVII = 11; % VII = 12; % since the annotations do not define whether they are maj or min 7ths
    CM7_center = [I,III,V,bVII] * bpst - midshift; % want to offset by midshift
    CM7(CM7_center) = 1 * 3/4; % JOS CHOSE 3/4 TO EQUALIZE SPECTRALLY FLAT TRIAD AND SEVENTH CHORDS
                               % Note that this only makes sense for perceptually flattened spectra/chroma
    if bpst>1
        CM7 = CM7 * toeplitz([ones(1,(bpst+1)/2),zeros(1,bpo-bpst),ones(1,(bpst-1)/2)]);
    end;
    Template(25,:) = CM7;
    for n = 26:36,
        prev = Template(n-1,:);
        Template(n,:) = circshift(prev,[0 bpo/12]);
    end;

    % Minor 7th chords (rows 37 to 48)
    cM7 = zeros(1,bpo);
    I = 1; bIII = 4; V = 8; bVII = 11; % VII = 12; % since the annotations do not define whether they are maj or min 7ths
    cM7_center = [I,bIII,V,bVII] * bpst - midshift; % want to offset by midshift
    cM7(cM7_center) = 1 * 3/4; % JOS CHOSE 3/4 TO EQUALIZE SPECTRALLY FLAT TRIAD AND SEVENTH CHORDS
    if bpst>1
        cM7 = cM7 * toeplitz([ones(1,(bpst+1)/2),zeros(1,bpo-bpst),ones(1,(bpst-1)/2)]);
    end;
    Template(37,:) = cM7;
    for n = 38:48,
        prev = Template(n-1,:);
        Template(n,:) = circshift(prev,[0 bpo/12]);
    end;
    % 'N' or 'X'
    % Template(49,:) = zeros(1, 12);
end;

% ------------- END GINA'S EDITS ------------- %

if doPlot
  screensize = get(0,'screensize');
  figPos = screensize([3,4,3,4]).*[0.6 0 0.4 0.4]; % upper right corner
  figurepos(figPos);
  [pitches_M,pitches_m,pitches_M7,pitches_m7] = getPitches(fmin);
  
  % Plot the Binary Template
  imagesc(Template);    
  % mesh(Template); % kind of fun
  title('Binary Template with Gaussian Distribution')
  set(gca,'XTick',1:round(bpo/12):bpo);
  set(gca,'XTickLabel',pitches_M);
  set(gca,'YTick',1:numchords);
  set(gca,'YDir','normal');
  ylabel([num2str(numchords),' templates']);
  if doPause, disp('PAUSING'); pause; end
end
