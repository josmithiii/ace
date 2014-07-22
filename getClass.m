%! function class = getClass(myChroma,cgsThresh)

% Class = 
% 1 for chord
% 2 for silence
% 3 for noise

cgMax = max(myChroma')'; % max over all time, each pitch class

[nChords,nFrames] = size(myChroma);

class = zeros(1,nFrames);

for m = 1:nFrames
  ccg = myChroma(:,m);
  dist =  cgMax - ccg; % distance to max
  if sum(dist<cgsThresh) < 3
   class(m) = 2;
  else
   class(m) = 1; % check for noise later
  end
end

