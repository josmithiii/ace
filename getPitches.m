function [pitches_M,pitches_m,pitches_M7,pitches_m7] = getPitches(fmin)
pitches_M = ['C  ';'C# ';'D  ';'D# ';'E  ';'F  ';'F# ';'G  ';'G# ';'A  ';'A# ';'B  '];
pitches_m = ['c  ';'c# ';'d  ';'d# ';'e  ';'f  ';'f# ';'g  ';'g# ';'a  ';'a# ';'b  '];
pitches_M7 = ['C7 ';'C#7';'D7 ';'D#7';'E7 ';'F7 ';'F#7';'G7 ';'G#7';'A7 ';'A#7';'B7 '];
pitches_m7 = ['c7 ';'c#7';'d7 ';'d#7';'e7 ';'f7 ';'f#7';'g7 ';'g#7';'a7 ';'a#7';'b7 '];
fmin_pitches = 65.4; % C
if fmin ~= fmin_pitches
  shifter = mod(round(log2(fmin/fmin_pitches)),12);
  pitches_M = circshift(pitches_M,shifter);
  pitches_m = circshift(pitches_m,shifter);
  pitches_M7 = circshift(pitches_M7,shifter);
  pitches_m7 = circshift(pitches_m7,shifter);
end

