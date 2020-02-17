function [ ] = create_slope_bty_file(pars, start_height, end_height)
%CREATE_BTY_FILE function creates a BTY file with a fixed slope bathymetry
%INPUTS:
% PARS - structure containing parameters needed for the BTY file,
%        (for complete list of the fields run 'help default_sim_pars' in the MATLAB console)
% START_HEIGHT - start height at zero range [m]
% END_HEIGHT - end height at maximum range [m]
%
%OUTPUT:
% BTY file is created at the same path as the parent ENV file for this simulation

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
filename = [pars.filename '.bty'];

% Calculate two bathymetry sample points to implement the slope
x_vect = [0, pars.maxrange] .* 1e-3;
y_vect = pars.maxdepth - [start_height, end_height];

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