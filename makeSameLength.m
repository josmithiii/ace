function [A,B] = makeSameLength(A,B)
A = A(:).';
B = B(:).';
lA=length(A);
lB = length(B);
if  lA ~= lB
  if lA>lB
    B = [B,zeros(1,lA-lB)];
  else
    A = [A,zeros(1,lB-lA)];
  end
end
