function kBelow = findIndexBelow(array,a,kLast)
% returns index of array just before it crosses a starting at kLast
len = length(array);
for k=kLast:len
  if array(k)>=a
    break;
  end
end
kBelow = k-1;
