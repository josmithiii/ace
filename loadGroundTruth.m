% Chord Recognition Project @ CCRMA 2014
% Sub module 7: Load the groud truth
% function: loadGroundTruth(labname)
% desc: This function is to parse the .lab ground truth file into a vector

function [ground_truth start_t end_t] = loadGroundTruth(labname,R,fmin,numchords,fs)

% inputs:
%        labname - name of the .lab file that contains the ground truth
%        R       - hopsize (samples)
%        fmin    - lowest analysis frequency 
%        fs      - fs after downsampling
% output:
%        ground_truth - ground truth chord
%        start_t      - start frame for each chord
%        end_t        - end frame for each chord

% (Note from Kitty): This is my way of parsing the .lab file,
% If you've come up with a simpler and more readable way, optimize it anytime :)

% Parsing .lab file
%%
disp(sprintf('loadGroundTruth: Reading file %s',labname));
fid = fopen(labname);                                    % file id
mycell = textscan(fid, '%f %f %s');                      % Scan
start_T = mycell{1};                                     % 1st column: start time
end_T = mycell{2};                                       % 2nd column: end time
chordname = mycell{3};                                   % 3rd column: chord name

% Map chordname into corresponding template class

% Convert into character
%capital = [];                                           % Empty array to store the first letter
% ---------- GINA's edits ------------ %
                                     % now handles sharps and flats!
                                     % these are for the MIREX annotations
                                     % capital = zeros(2,length(chordname));
for m = 1:length(chordname)
  true_chord = chordname{m};                           % (Directly becomes string)
  % get root name
  if length(true_chord) > 1 && (strcmp(chordname{2},'#')==1 || strcmp(true_chord(2),'b')==1),
capital = true_chord(1:2);                          % Get the first character in string as capital
  else,
    capital = true_chord(1);
end;

if capital == 'Ab'
id(m) = 9;
elseif capital == 'A'
id(m) = 10;
elseif capital == 'A#'
id(m) = 11;
elseif capital == 'Bb'
id(m) = 11;
elseif capital == 'B'
id(m) = 12;
elseif capital == 'C'
id(m) = 1;
elseif capital == 'C#'
id(m) = 2;
elseif capital == 'Db'
id(m) = 2;
elseif capital == 'D'
id(m) = 3;
elseif capital == 'D#'
id(m) = 4;
elseif capital == 'Eb'
id(m) = 4;
elseif capital == 'E'
id(m) = 5;
elseif capital == 'F'
id(m) = 6;
elseif capital == 'F#'
id(m) = 7;
elseif capital == 'Gb'
id(m) = 7;
elseif capital == 'G'
id(m) = 8;
elseif capital == 'G#'
id(m) = 9;
elseif capital == 'N'                      % Map Null to zero
id(m) = numchords+1;
elseif capital == 'X'
id(m) = numchords+1;
end;
end;

%         for m = 1:szid(2),                        % Map each id to corresponding pitch class
            %             switch id(m)
            %                 elseif capital == 'Ab'
            %                     id(m) = 9;
%                 elseif capital == 'A '
%                     id(m) = 10;
%                 elseif capital == 'A#'
%                     id(m) = 11;
%                 elseif capital == 'Bb'
%                     id(m) = 11;
%                 elseif capital == 'B '
%                     id(m) = 12;
%                 elseif capital == 'C '
%                     id(m) = 1;
%                 elseif capital == 'C#'
%                     id(m) = 2;
%                 elseif capital == 'Db'
%                     id(m) = 2;
%                 elseif capital == 'D '
%                     id(m) = 3;
%                 elseif capital == 'D#'
%                     id(m) = 4;
%                 elseif capital == 'Eb'
%                     id(m) = 4;
%                 elseif capital == 'E '
%                     id(m) = 5;
%                 elseif capital == 'F '
%                     id(m) = 6;
%                 elseif capital == 'F#'
%                     id(m) = 7;
%                 elseif capital == 'Gb'
%                     id(m) = 7;
%                 elseif capital == 'G '
%                     id(m) = 8;
%                 elseif capital == 'G#'
%                     id(m) = 9;
%                 elseif capital == 'N '                            % Map Null to zero
%                     id(m) = 0;
%                 elseif capital == 'X '
%                     id(m) = 0;
%             end
%             
%             if id(m) ~= 0,
%                 id3(m) = 1 + mod(id(m)-1+shifter,12);
%             else,
%                 id3(m) = 0;
%             end;
%         end

% Now I have an array of number between 1-12, and 0 for N or X
% Initialize chord template to id (size is [1,nFrames])
ground_truth = id;

% place the chord on the template
for m = 1:length(chordname)
  true_chord = chordname{m};
% determine if there's a seventh
    seventh = 0;
    if true_chord(end) == '7' && numchords > 24,
        seventh = 1;
    end;

    %fourth = ' ';

    % determine quality
    if length(true_chord) > 4,
        if true_chord(3) == 'm',                % If the name length > 2, e.g: F:maj
            fourth = true_chord(4);               % look at the fourth character
        elseif true_chord(4) == 'm',            % If we have F#:maj or min
            fourth = true_chord(5);
        end;
    else
        fourth = ' ';                           % 2014-06-29 editing,for others
    end;

    % place the chord on the template
    if true_chord(1) == 'N' || true_chord(1) == 'X',
    % should be something like, numchords + 1; way to plot an "N" chord
      ground_truth(m) = numchords+1;
    elseif length(true_chord) < 3,
        ground_truth(m) = id(m);
    elseif (fourth == 'a' && seventh == 0),
        ground_truth(m) = id(m);
    elseif length(true_chord) < 5 && seventh == 1, % some chords don't have a 'min' or 'maj' but still have a '7'
ground_truth(m) = id(m) + 24;
elseif fourth == 'i' && seventh == 0,  % If it is i, e.g F:min
ground_truth(m) = id(m) + 12;     % Map to minor chord template index
elseif fourth == 'a' && seventh == 1,
ground_truth(m) = id(m) + 24;
elseif fourth == 'i' && seventh == 1,
ground_truth(m) = id(m) + 36;
disp(sprintf('minor and seventh %i', m));
end;
end

% disp('ground truth:');
% disp(sprintf('%d',ground_truth));

% id

% capital is a vector contains ascii code for the chord name
% using this to access the actual name of the chord 
% truth_char = char(truth_ids);

% Map capital into 24 templates with id 1-12
% Thankfully, there's no sharp in the ground truth

%  2  4     7  9   11
%  C# D#   F# G#   A#
% C  D  E F  G   A    B
% 1  3  5 6  8  10    12

% 1. Consider everything is Major

% 2. Find the minor chords
% Look at chordname{n}, check the length
% If length = 1, remain unchange;   e.g F  E 
% If length > 1, e.g F:maj   E:min,
% look at the fourth character, should be either a or i
% if it is 'a', then it's a major chord, remain unchange
% if it is 'i', then it's a minor chord, map to corresponding minor id
% by simply plus 12 (M: 1-12  m: 13-24)

%  2  4     7  9   11       14  16     19   21  23
%  C# D#   F# G#   A#       c#  d#     f#   g#  a#
% C  D  E F  G   A    B   c   d   e  f    g   a   b 
% 1  3  5 6  8  10    12  13  15  17 18   20  22  24
% As Binary Template created before
% Major Chords (row 1 to 12)
% Minor Chords (row 13 to 24) -- just simply plus 12

%         for n = 1:length(id)
%             true_chord = chordname{n};               % Look at the whole name
%             if length(true_chord) > 4                % If the name length > 1 (4 for safe), e.g: F:major
%                fourth = true_chord(4);               % look at the fourth character
%                if fourth == 'i'                      % If it is i, e.g F:minor
%                    ground_truth(n) = id(n) + 12;     % Map to minor chord template index
%                end
%             end
%         end

% Map starting/ending time to specific frame number
if 0 % when are frames better than seconds?
  start_t = floor(start_T * fs/R);
  end_t = floor(end_T * fs/R);
else
  start_t = start_T;
  end_t = end_T;
end
