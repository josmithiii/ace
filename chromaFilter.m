% Chord Recognition Project @ CCRMA 2014
% Sub module: chromaFilter
% desc: Pre-Processing the chromagram using the moving median filter

% function: getChroma(mySpec,beta,Z)
% inputs: 
%        chroma -- unfiltered chromagram
%        beta   -- bins per octave
%        winL   -- length of the moving window
% output:
%        Chromagram -- The chromagram after moving median filter

% TO-DO : Test with other filters? (moving average/...)

function chroma_smooth = chromaFilter(chroma,beta,winL)
        zeroP = zeros(beta,floor(winL/2));                 % zero pad amount: 7 frames each
        chroma_Z = [zeroP chroma zeroP];                   % zero pad in the beginning and in the end
        chroma_smooth = zeros(size(chroma));
        for frm = 1:size(chroma,2)                         % For each frame
            chunk = chroma_Z(:,frm:frm+winL-1);            % Select a chunk 
            chroma_smooth(:,frm) = median(chunk,2);        % Take the median
        end
end