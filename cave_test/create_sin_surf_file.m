function [x_vect, waves] = create_sin_surf_file(pars, wave_length, wave_height, phase_shift)
%CREATE_SIN_SURF_FILE function creates an ATI file for a sinusoidal surface wave
%INPUTS:
% PARS - structure containing parameters needed for the ATI file,
%        (for complete list of the fields run 'help default_sim_pars' in the MATLAB console)
%
%OUTPUT:
% ATI file is created at the same path as the parent ENV file for this simulation

% Copyright 2020 Nils Morozs, University of York (nils.morozs@york.ac.uk)
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
% associated documentation files (the "Software"), to deal in the Software without restriction,
% including without limitation the rights to use, copy, modify, merge, publish, distribute,
% sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial
% portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
% NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
% OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% This work was supported by the UK Engineering and Physical Sciences Research Council (EPSRC) 
% through the USMART Project under Grant EP/P017975/1.
    
% Create an output ATI file
filename = [pars.filename '.ati'];

% Calculate sinusoidal bottom coordinates with specified period (-pi/2 shift to start at maximum depth at range 0)
resolution  = pars.wave_resolution; % spatial resolution
x_vect = (0:resolution:1.01*pars.maxrange) .* 1e-3;
waves = (sin(phase_shift + x_vect.*2.*pi./(wave_length.*1e-3)) + 1) .* wave_height ./ 2;
waves  = waves + (rand([1 numel(waves)])-0.5).*(wave_height/20); % random small scale roughness
waves = abs(waves - max(waves)); % make sure they are all below zero (for BELLHOP compatibility)

% Open a file output stream
fid = fopen(filename, 'w');

% Write first two lines
fprintf(fid, '''L''\n');
fprintf(fid, '%d\n', numel(waves));

% Now write the XY coordinate pairs line by line
for n = 1:numel(waves)
    fprintf(fid, '%f\t%f\n', (n-1)*resolution*1e-3, waves(n));
end

% Close the file
fclose(fid);
