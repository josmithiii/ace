function [fid] = openLogFile(logfiledir,logfileroot,ext);
nowstamp = datestr(now,'yyyy-mm-dd-HH-MM-SS');
logfile = [logfiledir,'/',logfileroot,'.',ext]; 
if exist(logfiledir)~=7
  mkdir(logfiledir);
end
if exist(logfile)==2
  movefile(logfile,[logfiledir,'/',logfileroot,'-',nowstamp,'.',ext]);
end
fid = fopen(logfile,'w');
