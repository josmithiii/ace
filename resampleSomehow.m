function wave = resampleSomehow(wave,fsds,fs);
downsamp = fsds/fs; % Audio downsampling factor
% wave = downsample(wave,round(downsamp)); % no anti-aliasing!
% wave = decimate(wave,round(downsamp)); % requires integer conversion ratio
% if exist('upfirdn')==2 % Fails to even do the test on Mac Ports!
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if ~isOctave % resample() should work fine in Matlab
% [numrs,denrs]  = rat(downsamp);
  numrs = round(fsds);
  denrs = round(fs);
  disp(sprintf('Converting sampling-rate by the factor %d/%d',numrs,denrs));
  wave = resample(wave,numrs,denrs); % Fails in Octave on the Mac (Mac Ports)
else
  disp(sprintf('Converting sampling-rate by the factor %f = %d / %d:',downsamp,fsds,fs));
  tempdir = './tempWavFiles/';
  [status,msg,msgid] = mkdir(tempdir);
  infile = [tempdir,'in.wav'];
  outfile = [tempdir,'out.wav'];
  if status==0
    error('resampleSomehow: Cannot create temporary directory %s\n\t%s',tempdir,msg);
  end
  if system('which sndfile-resample')==0
    % Nicer than sox because it restarts if clipping detected:
    cmd = sprintf('sndfile-resample -to %f %s %s',fsds,infile,outfile);
  elseif  system('which sox')==0
    cmd = sprintf('sox %s -r %f %s',infile,fsds,outfile);
  else
    error('resampleSomehow: Must install libsamplerate or sox, or use Matlab');
  end
  wavwrite(wave,fs,infile);
  disp(cmd);
  system(cmd);
  [wave,fsread] = wavread(outfile);
  if fsread ~= fsds
    warning('resampleSomehow: Wanted sampling-rate %f and got %f instead',fsds,fsread);
  end
end
