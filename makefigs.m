% Run after running ACE.m

a = aweighting(fc);
g = gaussweighting(fc);

figure();
%plot(fc,a,fc,g);
%stem(fc,[a',g']); 
%stem(fc,a,'x'); hold('on'); stem(fc,g,'o'); 
plot(fc,a,'-*k',fc,g,'--ok');
grid('on');
legend('A-Weighting','Gauss-Weighting');
xlabel('Frequency (Hz)');
ylabel('Gain');
print -mono -deps2 '../aes14/eps/weightings.eps';

disp('Now edit the bounding box to move the y origin from 0 to 50');
