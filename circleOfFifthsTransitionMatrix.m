function A = circleOfFifthsTransitionMatrix(numchords)

% this is where our HMM goes
% size(A) = [numchords+1,numchords+1];

% Circle of fifths example when a C triad is the first row:
% Assign probability of transition p according to the clockwise
% angular closeness:
%    C  G  D  A  E  B  F# C# Ab Eb Bb F
% p: 12 10 8  6  4  2  0  2  4  6  8  10
%    e  b  f# c# ab eb bb f  c  g  d  a
% p: 11 9  7  5  3  1  1  3  5  7  9  11      
% For example, the first row becomes
% [12 2 8 6 4 10 0 10 4 6 8 2 12 5 9 1 11 3 7 7 3 11 1 9];

% Create the top left partition of the transition matrix A:
% Assigning
%     C  G  D  A  E  B  F# C# Ab Eb Bb F
% p   12 10 8  6  4  2  0  2  4  6  8  10
A_1_1 = zeros(12,12);
first = [12 2 8 6 4 10 0 10 4 6 8 2];
eu = 0.001;                            % eu: Small smoothing constant
A_1_1(1,:) = (first+eu)/(144+24*eu);   % p value in the first row: for C
for i = 2:12
  A_1_1(i,:) = circshift(A_1_1(1,:),[0,i-1]);
end

% Create top right partition:
A_1_2 = zeros(12,12);
first = [12 5 9 1 11 3 7 7 3 11 1 9];
eu = 0.0001;
A_1_2(1,:) = (first+eu)/(144+24*eu);  
for i = 2:12
  A_1_2(i,:) = circshift(A_1_2(1,:),[0,i-1]);
end

% Bottom right partition = same as top left:
A_2_2 = A_1_1;

% Bottom left partition = transpose of top right:
A_2_1 = A_1_2';

% Form full transition probability matrix from its partitions:
A = [A_1_1, A_1_2; A_2_1, A_2_2]; 
if numchords == 48,
    A = repmat(A,2);
end


A = [A, zeros(length(A),1)];
A = [A; zeros(1,numchords+1)];
%A = [A, zeros(numchords,1); zeros(1,numchords+1)]; % use this for the
% 'N'/'X' case
% Normalize to sum 1:
A = A ./ repmat(sum(A),size(A,1),1);

% Apply Penalty
penalty = -1.2;
  tempMat = (ones(numchords+1) - diag(ones(numchords+1,1))) * exp(penalty);
% tempMat = (ones(numchords) - diag(ones(numchords,1))) * exp(penalty);
  PenaltyMat = diag(ones(numchords+1,1)) + tempMat;
% PenaltyMat = diag(ones(numchords,1)) + tempMat;
A = A .* PenaltyMat;
% find nans
thenans = isnan(A);
A(thenans) = 0;
