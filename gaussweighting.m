% Source (and doc): http://en.wikipedia.org/wiki/A-weighting

% exp(-(p-60)^2/(2*15^2)); % p MIDI key number: 60 = C4

% This Gauss-weighting should be applied to the magnitude spectrum
% (not power spectrum or dB).  It is used in Cho and Bello 2014.

function gwt = gaussweighting(fc) % fc = sample frequencies in Hz

fckn = 12*log2(fc/440.0) + 49.0;
gwt = exp(-(fckn-60) .^ 2 ./ (2*15^2));
gwt = gwt/max(gwt);

if nargout==0
  plot(fc,gwt,'-*');
  xlabel('Frequency (Hz)');
  ylabel('Amplitude (Linear)');
  title('Gauss-weighting used by Cho and Bello 2014');
end
