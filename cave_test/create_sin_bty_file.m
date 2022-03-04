function [x_vect, y_vect] = create_sin_bty_file(pars, phase_shift)
%CREATE_SIN_BTY_FILE function creates a BTY file with a sinusoidal bathymetry with random height for every hill
%INPUTS:
% PARS - structure containing parameters needed for the BTY file,
%        (for complete list of the fields run 'help default_sim_pars' in the MATLAB console)
%
%OUTPUT:
% BTY file is created at the same path as the parent ENV file for this simulation

% Copyright 2022 Nils Morozs, University of York (nils.morozs@york.ac.uk)
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
    
% Create an output BTY file
filename = [pars.filename '.bty'];

% Calculate sinusoidal bottom coordinates with specified period (-pi/2 shift to start at maximum depth at range 0)
samples_per_period = 32;
x_vect = (0:pars.hill_length/samples_per_period:1.01*pars.maxrange) .* 1e-3;
sin_hill_vect = (sin(phase_shift + x_vect.*2.*pi./(pars.hill_length.*1e-3)) + 1) .* pars.max_hill_height ./ 2;
sin_hill_vect  = sin_hill_vect + rand([1 numel(sin_hill_vect)]).*(pars.max_hill_height/20); % random small scale roughness

% Multiply every wavelength (hill) by a random factor and subtract from the maximum depth to obtain absolute depth
y_vect = pars.maxdepth - sin_hill_vect;

% Open a file output stream
fid = fopen(filename, 'w');

% Write first two lines
fprintf(fid, '''L''\n');
fprintf(fid, '%d\n', numel(x_vect));

% Now write the XY coordinate pairs line by line
for n = 1:numel(x_vect)
    fprintf(fid, '%f\t%f\n', x_vect(n), y_vect(n));
end


% Close the file
fclose(fid);