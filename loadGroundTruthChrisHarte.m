function [ground_truth, start_t, end_t, bassnote] = loadGroundTruthChrisHarte(labname, numchords, doBass)
% Parses chord and relates it to an index corresponding to a template with
% numchords chords. So, for example, 'C:maj' would correspond to index 1,
% 'B:min' would correspond to index 24. If numchords==24, then B:min7 would
% also correspond to index 24. If numchords==48, then it would correspond
% to 48.

% Uses a lot of code from loadGroundTruth.m, but this only handles one
% chord at a time.

% Parsing .lab file
disp(sprintf('loadGroundTruth: Reading file %s',labname));
fid = fopen(labname);                                    % file id
mycell = textscan(fid, '%f %f %s');                      % Scan
start_T = mycell{1};                                     % 1st column: start time
end_T = mycell{2};                                       % 2nd column: end time
chordname = mycell{3};                                   % 3rd column: chord name
% free up memory
cl = fclose(fid);

for m = 1:length(chordname),
    true_chord = chordname{m};                           % (Directly becomes string)
    % get root name
    if length(true_chord) > 1 
        if strcmp(true_chord(2),'#')==1 || strcmp(true_chord(2),'b')==1,
            capital = true_chord(1:2);                   % Get the first character in string as capital
        else
            capital = true_chord(1);
        end;
    else
        capital = true_chord(1);
    end;

    if capital == 'Ab'
        id = 9;
    elseif capital == 'A'
        id = 10;
    elseif capital == 'A#'
        id = 11;
    elseif capital == 'Bb'
        id = 11;
    elseif capital == 'B'
        id = 12;
    elseif capital == 'C'
        id = 1;
    elseif capital == 'C#'
        id = 2;
    elseif capital == 'Db'
        id = 2;
    elseif capital == 'D'
        id = 3;
    elseif capital == 'D#'
        id = 4;
    elseif capital == 'Eb'
        id = 4;
    elseif capital == 'E'
        id = 5;
    elseif capital == 'F'
        id = 6;
    elseif capital == 'F#'
        id = 7;
    elseif capital == 'Gb'
        id = 7;
    elseif capital == 'G'
        id = 8;
    elseif capital == 'G#'
        id = 9;
    elseif capital == 'N'                      % Map Null to zero
        id = numchords+1;
    elseif capital == 'X'
        id = numchords+1;
    end;

    % Now I have an array of number between 1-12, and numchords+1 for N or X

    % For Harte-specific inversion/seventh notation...
    % intialize "bassnote" vector
    bassnote = id; flat_bass = 0; sharp_bass = 0; two = 0; three = 1; five = 0; seven = 0; 
    % bassnote will be mod(id + bassnote, 12), ish...
    % find '(' and '/' and ignore that shit
    slash_index = find(true_chord=='/',1,'first');
    if slash_index
        if doBass,
            addl = str2num(true_chord(end));
            if addl == 2 || addl == 9,
                bassnote = mod(bassnote + 2, 12);
                if bassnote == 0, bassnote = 12; end;
                two = 1; % flag for second to check later if it's quality-dependent
            elseif addl == 3,
                bassnote = mod(bassnote + 4, 12); % check later if the chord is minor/diminished, and subtract one
                if bassnote == 0, bassnote = 12; end;
                three = 1;
            elseif addl == 5,
                bassnote = mod(bassnote + 7, 12); % check later if the chord is diminished, and subtract one
                if bassnote == 0, bassnote = 12; end;
                five = 1;
            elseif addl == 7,
                bassnote = mod(bassnote + 10, 12); % check later if it's a maj7
                if bassnote == 0, bassnote = 12; end;
                seven = 1;
            end;
            if length(true_chord)-slash_index == 2, % then we have a sharp or a flat, since there's no "/11" i don't think...
                if true_chord(slash_index+1)=='b', 
                    bassnote = bassnote-1;
                    if bassnote == 0, bassnote = 12; end;
                    flat_bass = 1;
                    sharp_bass = 0;
                elseif true_chord(slash_index+1)=='#',
                    bassnote = mod(bassnote+1,12);
                    if bassnote == 0, bassnote = 12; end;
                    flat_bass = 0;
                    sharp_bass = 1;
                end;
            end;
        end; % end bassnote detection
        true_chord = true_chord(1:slash_index-1); % ditch everything after and including the slash
    end;
    paren_index = find(true_chord=='(',1,'first');
    if paren_index
        true_chord = true_chord(1:paren_index-1);
    end;

    % in some cases this leaves a dangling ':', which is a major chord
    if true_chord(end) == ':',
        true_chord = true_chord(1:end-1);
    end;

%     if length(true_chord) > 2,
%         if true_chord(end-1) == '/',
%             bassnote = true_chord(end);
%             true_chord = true_chord(1:end-2); % drop the slash, too
%         elseif true_chord(end-2) == '/',
%             bassnote = true_chord(end-1:end);
%             true_chord = true_chord(1:end-3);
%         end;
%     end;
%     
%     % ignore shit in parentheses; just refers to non-chord tones that
%     % aren't the root, i assume
%     if length(true_chord) > 4,
%         if true_chord(end-2) == '(',
%             true_chord = true_chord(1:end-3);
%         elseif true_chord(end-3) == '(',
%             true_chord = true_chord(1:end-4);
%         elseif true_chord(end-3) == '/', % potentially a "b11" could exist?
%             bassnote = true_chord(end-2:end);
%             true_chord = true_chord(1:end-4);
%         end;
%     end;

    % determine if there's a seventh
    seventh = 0; % initialize
    if true_chord(end) == '7' || true_chord(end) == '9', % don't care whether it's a maj7 or min7 in our template
        seventh = 1;
    end;

    % determine quality
    fourth = 'n'; % initialize
    if length(true_chord) > 4,
        if true_chord(3) == 'm' || true_chord(4) == 'u' || true_chord(3) == 'd' || true_chord(3) == 'h', % e.g. 'F:maj','F:min','F:aug','F:dim'
            fourth = true_chord(4); % quality will be either 'a' (maj), 'u' (aug), 'i' (dim), or 'd' (hdim)
        elseif true_chord(4) == 'm' || true_chord(5) == 'u' || true_chord(4) == 'd' || true_chord(4) == 'h', % e.g. 'F#:maj',...,'F#:dim'
            fourth = true_chord(5);
        elseif true_chord(3) == 's', % if sustained
            fourth = 'a'; % call it major
        end;
    end;

    % numchords = 24
    if numchords == 24,
        if true_chord(1) == 'N' || true_chord(1) == 'X',
            chordindex(m) = numchords+1; % map the 'silence' case to an unused index
        elseif fourth == 'i',
            chordindex(m) = id + 12;
        else
            chordindex(m) = id;
        end;
    end;

    if numchords == 48,
        % place the chord on the template (applies to 24 and 48 numchords)
        if true_chord(1) == 'N' || true_chord(1) == 'X',
            chordindex(m) = numchords+1; % map the 'silence' case to an unused index
        elseif length(true_chord) < 3, % e.g. 'F' or 'F#'
            chordindex(m) = id;
        elseif fourth == 'a' || fourth == 'u' && seventh == 0, % e.g. 'F:maj' or 'F#:maj', 'F:aug' or 'F#:aug'
            chordindex(m) = id;
            if five, bassnote = bassnote + 1; end;
            if bassnote == 13, bassnote = 1; end;
        elseif length(true_chord) < 5 && seventh == 1, % e.g. 'F:7' or 'F#:7'
            chordindex(m) = id + 24;
        elseif fourth == 'i' && seventh == 0,  % e.g. 'F:min','F#:min','F:dim','F#:dim'
            chordindex(m) = id + 12;
            if three, bassnote = bassnote - 1; end;
            if bassnote == 0, bassnote = 12; end;
        elseif fourth == 'a' && seventh == 1, % e.g. 'F:maj7','F#:maj7','F:majmin7', etc.
            chordindex(m) = id + 24;
            if seven && true_chord(end-2) == 'a', bassnote = mod(bassnote + 1, 12); end;
            if bassnote == 0, bassnote = 12; end; 
        elseif fourth == 'i' && seventh == 1, % e.g. 'F:min7','F#:min7','F:dim7','F#:dim7','F:minmaj7',...,'F#:dimmaj7'
            chordindex(m) = id + 36;
            if seven && true_chord(end-2) == 'a', bassnote = mod(bassnote + 1, 12); end;
            if bassnote == 0, bassnote = 12; end; 
        elseif fourth == 'u' && seventh == 1, % e.g. 'F:aug7' or 'F#:aug7'
            chordindex(m) = id + 24;
            if five, bassnote = bassnote + 1; end;
            if bassnote == 13, bassnote = 1; end;
        elseif fourth == 'd' && seventh == 0, % e.g. 'F:hdim' or 'F#:hdim'
            chordindex(m) = id + 12;
            if three || five, bassnote = bassnote - 1; end;
            if bassnote == 0, bassnote = 12; end;
        elseif fourth == 'd' && seventh == 1, % e.g. 'F:hdim7', ..., 'F#:hdimmaj7' (which would be redundant, btw)
            chordindex(m) = id + 36;
            if three || five, bassnote = bassnote - 1; end;
            if bassnote == 0, bassnote = 12; end;
        end;
    end;
end;

ground_truth = chordindex;

% Map starting/ending time to specific frame number
if 0 % when are frames better than seconds?
  start_t = floor(start_T * fs/R);
  end_t = floor(end_T * fs/R);
else,
  start_t = start_T;
  end_t = end_T;
end;
