%! function [loudSpec,tMGB,fMGB] = getLoudness(loudnessModel,wave,mySpec,fc,R,fs,doPlot,doPause);

minDB = -100;

switch loudnessModel
 case 0
  disp('sqrt(mag):');
  loudSpec = sqrt(sqrt(mySpec));
 case 1
  disp('mag:');
  loudSpec = sqrt(mySpec);
 case 2
  disp('mag^2:');
  loudSpec = mySpec;
 case 3
  disp('Unweighted DB:');
  loudSpec = 0.5*dbn(mySpec,2*minDB)-minDB; % convert to normalized dB,
 case 4
  disp('A-weighted DB:');
  loudSpec = getLoudSpec(mySpec,fc,R,fs,minDB,doPlot,doPause); % ./getLoudSpec.m
 case 5
  disp('dB(Gauss-weighted-magnitude):');
  gwt = gaussweighting(fc);
  gwtmagsq = gwt .* gwt; % Convert to a mag-squared weighting
  %! mySpecGaussWeighted = diag(gwtmagsq) * mySpec; % Gauss^2-weighted mag^2 vs time
  %! loudSpec = 0.5*dbn(mySpecGaussWeighted,2*minDB)-minDB; % convert to normalized dB,
  mySpecGaussWeighted = diag(gwtmagsq) * sqrt(mySpec); % TESTING 1 2
 case 6
  if ~(exist('Loudness_LMIS') == 2)
      addpath('./LoudnessToolboxV1p2/','-begin');
      if ~(exist('Loudness_LMIS') == 2)
        error('Install LoudnessToolboxV1p2 in the ACE directory');
      end
  end
  disp('MGB:');
  waveScale = 20; % map amplitude 1 to 20 Pascals = "very loud"
  % "Reference" is 2e-5 Pascals for dB calculations
  % disp(sprintf('*** Scaling waveform by %d for MGB',waveScale));
  wave = waveScale*wave; 
  tic;
  % ./LoudnessToolboxV1p2/Loudness_TimeVaryingSound_Moore.m
  % res = Loudness_TimeVaryingSound_Moore(wave, fs, 'mic', doPlot);
  signal=wave; FS=fs; type='mic'; show=doPlot; nargin=4; 
  Loudness_TimeVaryingSound_Moore; % computes res
  tMGB = res.time;
  fMGB = res.frequency;
  loudSpec = res.InstantaneousSpecificLoudness;
  mgbTime = toc;
  disp(sprintf(...
   'MGB computation time = %0.3f msec/sample = %0.3f sec = %0.3fx real time',...
      1000*mgbTime/length(wave),mgbTime,(length(wave)/fs)/mgbTime));
% if doPlot
  plotSpecificLoudness(res,wave,fs); % ./plotSpecificLoudness.m
% end
  wave = wave/waveScale; % in case there are more cases
  disp(sprintf('MGB Specific Loudness dimensions are %d x %d',size(res.InstantaneousSpecificLoudness)));
  disp(sprintf('Other spectrogram dimensions are %d x %d',size(mySpec)));
 otherwise
  error('getLoudness: Unknown loudnessModel');
end

if (nargout>1) && (loudnessModel~=4)
  error(sprintf('getLoudness: no time-freq axes returned for loudness model %d',loudnessModel));
end

% 0 - Magnitude-Squared Spectrum
% 1 - A-Weighted dB
% 2 - Loudness_ANSI_S34_2007
% 3 - Loudness_ISO532B
% 4 - Loudness_ISO532B_from_sound
% 5 - Loudness_LMIS
% 6 - Loudness_TimeVaryingSound_Moore
% 7 - Loudness_TimeVaryingSound_Zwicker
