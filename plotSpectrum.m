function plotSpectrum(s,fs)

setenv('GNUTERM','aqua')
graphics_toolkit('fltk');

Nfft = 2^nextpow2(length(s));
N = length(s);
w = hanning(N);
S = fft(s(:) .* w(:), Nfft);
Sdb = dbn(S(1:Nfft/2));

freqs = fs * [0:Nfft/2-1]/Nfft;

figure();
subplot(2,1,1);
semilogx(freqs(2:end),Sdb(2:end));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

subplot(2,1,2);
plot(freqs,Sdb);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
