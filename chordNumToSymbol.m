% Convert chord number to symbol used in .lab files (ACE ground truth)

% If you think this function is ugly, you would be correct

function symbol = chordNumToSymbol(chordNum,numchords,fmin);
[pitches_M,pitches_m,pitches_M7,pitches_m7] = getPitches(fmin); % ./getPitches.m
if numchords==24
  if chordNum <= 12
    symbol = pitches_M(chordNum,:);
  elseif chordNum <= 24
    symbol = pitches_m(chordNum-12,:);
    symbol = symbol(find(symbol ~= ' '));
    symbol = [toupper(symbol),':min'];
  elseif chordNum==25
    symbol = 'N';
  else
    error('chordNumToSymbol.m: Cannot handle chordNum == %d',chordNum);
  end
elseif numchords==48
  if chordNum <= 12
    symbol = pitches_M(chordNum,:);
  elseif chordNum <= 24
    symbol = pitches_m(chordNum-12,:);
    symbol = symbol(find(symbol ~= ' '));
    symbol = [toupper(symbol),':min'];
  elseif chordNum <= 36
    symbol = pitches_M7(chordNum-24,:);
    symbol = symbol(find(symbol ~= ' '));
    symbol = symbol(find(symbol ~= '7'));
    symbol = [symbol,':7'];
  elseif chordNum <= 48
    symbol = pitches_m7(chordNum-36,:);
    symbol = symbol(find(symbol ~= ' '));
    symbol = symbol(find(symbol ~= '7'));
    symbol = [toupper(symbol),':min7'];
  elseif chordNum == 49
    symbol = 'N';
  else
    error('chordNumToSymbol.m: Cannot handle chordNum == %d',chordNum);
  end
else
  error('chordNumToSymbol.m: Cannot handle numchords == %d',numchords);
end
