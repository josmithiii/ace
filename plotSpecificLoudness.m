function plotSpecificLoudness(res,wave,fs)
t = res.time;
f = res.frequency;
ILphon = res.InstantaneousLoudnessLevel;
ISLphon = res.InstantaneousSpecificLoudness; % phon/ERB?
STLsone = res.STL;
STLsoneMax = res.STLmax;
LTLsone = res.LTL;
LTLsoneMax = res.LTLmax;
STLphon = res.STLlevel;
STLphonMax = res.STLlevelmax;
LTLphon = res.LTLlevel;
LTLphonMax = res.LTLlevelmax;
disp('MGB Instantaneous (IL), Short-Term (STL), and Long-Term Loudness (LTL)');

disp(sprintf('In Sones: Max STL = %0.2f, Max LTL = %0.2f', STLsoneMax, LTLsoneMax));
disp(sprintf('In Phons: Max STL = %0.2f, Max LTL = %0.2f', STLphonMax, LTLphonMax));

m = min( min(ISLphon) );
if m ~= 0
  warning(sprintf('Expected Minimum Specific Loudness zero but found %f',m));
end
M = max( max(ISLphon) );
disp(sprintf('Max Specific Loudness = %f',M));
clipLevel = M-40; % Hard to see much more than this

% figure;
% mesh(f',t,max(ISLphon,clipLevel));
% xlabel('Time (s)'); ylabel('Frequency (Hz)'); zlabel('Loudness (sone/ERB)');
% title('MGB Specific Loudness - mesh');

figure;
colormap('gray'); map = colormap; imap = flipud(map);
% imagesc(f,t, ISLphon', [clipLevel M]); axis xy; colormap(jet);
imagesc(t,f,ISLphon); axis xy;
xlabel('Time (s)'); ylabel('Frequency (Hz)');
title('MGB Specific Loudness - imagesc');
colormap(imap);

figure;
subplot(2,1,1)
plot(t,[ILphon',STLphon',LTLphon']); grid('on');
%plot(t,ILphon',t,STLphon','r',t,LTLphon','g');
legend('IL','STL','LTL');
title( 'MGB Instantaneous, Short-Term, and Long-Term Loudness Curves');
xlabel('Time, s');
ylabel('Loudness Level, Phons');

subplot(2,1,2)
plot(0:1/fs:(length(wave)-1)/fs,wave); grid('on');
title('Signal');
xlabel('Time, s');
ylabel('Pressure, Pa');
