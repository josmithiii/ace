function loudSpec = getLoudSpec(mySpec,fc,R,fs,minDB,doPlot,doPause)

% Convert spectral magnitude-squared in mySpec at frequencies fc to LOUDNESS.

% FIXME: Could replace the Constant-Q spectrogram in getSpec.m with
% the Genesis loudness spectrogram, or use the HPA loudness measure.
% For a placeholder, we simply form A-weighted dB for now (shouldn't
% be too bad, actually, although low-frequencies might be
% down-weighted too much).

% ./aweighting.m
awt = aweighting(fc);  % Weighting for a magnitude spectrum near 40 phons
awtmagsq = awt .* awt; % Convert to a mag-squared weighting
mySpecAWeighted = diag(awtmagsq) * mySpec; % A-weighted mag^2 vs time
minMagSq = 10^(minDB/10);
loudSpec = 0.5*dbn(mySpecAWeighted+minMagSq); % convert to normalized dB, 
%loudSpec = 0.5*dbn(mySpecAWeighted,2*minDB)-minDB; % convert to normalized dB, 

