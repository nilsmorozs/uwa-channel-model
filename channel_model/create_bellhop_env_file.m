function [ ] = create_bellhop_env_file(pars)
%CREATE_BELLHOP_ENV_FILE function creates an ENV file in a format that can
% be used by the BELLHOP ray tracing program
%INPUTS:
% PARS - structure containing parameters needed for the ENV file,
%        (for complete list of the fields run 'help default_sim_pars' in the MATLAB console)
%
%OUTPUT:
% ENV file is created at the path specified in PARS.FILENAME

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

% Add ".env" extension to the file name
env_filename = [pars.filename, '.env'];

% Open a file output stream
fid = fopen(env_filename, 'w');

% Write the first three lines to file
fprintf(fid, '''%s''\n', pars.title);
fprintf(fid, '%f \t\t\t\t! Carrier frequency\n', pars.freq);
fprintf(fid, '1 \t\t\t\t\t\t! number of media (unused in BELLHOP)\n');

% Thorp absoption character
if isfield(pars, 'thorpabsorb') && pars.thorpabsorb; abs_string = 'T'; else; abs_string = ' '; end
% Custom altimetry character
if pars.use_altimetry; alt_string = '*'; else; alt_string = ''; end
% Write next to line to ENV file
fprintf(fid, ['''SVF', abs_string, alt_string, ...
              ''' \t\t\t\t\t! Spline interp, Vacuum ocean surf, dB units of loss, T - Thorp absorption loss, * - custom altimetry\n']);

% Sort the sound speed profile datapoints by depth, just in case
[pars.depths, ind] = sort(pars.depths);
pars.soundspeeds = pars.soundspeeds(ind);

% Write the sound speed profile vector to the file
fprintf(fid, '%d\t%f\t%f \t! Number of datapoints, min depth [m], max depth [m]\n',...
              numel(pars.depths), pars.depths(1), pars.depths(end));
for n = 1:numel(pars.depths)
    fprintf(fid, '\t%f\t\t%f /\n', pars.depths(n), pars.soundspeeds(n));
end

% Write two lines describing the ocean bottom
if pars.use_bathymetry
    fprintf(fid, '''A*'' 0.0 \t\t\t\t\t! Bottom is an Acousto-Elastic halfspace, custom bathymetry\n');
else
    fprintf(fid, '''A '' 0.0 \t\t\t\t\t! Bottom is an Acousto-Elastic halfspace, flat bathymetry\n');
end
fprintf(fid, '%f 1600.0 0.0 1.0 /\t! Bottom has 1600 m/s sound speed and unit density\n', pars.depths(end));

% Write two lines describing locations of the acoustic sources
fprintf(fid, '%d \t\t\t\t\t\t\t! Number of sources\n', numel(pars.sourcedepths));
for n = 1:numel(pars.sourcedepths)
    fprintf(fid, '%f ', pars.sourcedepths(n));
end
fprintf(fid, '/ \t\t! Source depths [m]\n');

% Now specify receiver depths and ranges based on the type of simulation
if strcmp(pars.simtype, 'loss')
    % For transmission loss simulation, use fine grid of points
    fprintf(fid, '201 \t\t\t\t\t\t\t! Number of receiver depths\n');
    fprintf(fid, '0.00 %f /\t\t\t\t! Receiver point depth range [m]\n', pars.depths(end));
    fprintf(fid, '1001 \t\t\t\t\t\t! Number of receiver ranges\n');
    fprintf(fid, '0.00 %f /\t\t\t\t! Receiver range limits [km]\n', pars.maxrange*1e-3);
elseif strcmp(pars.simtype, 'ray')
    % For ray tracing simulation, use the same resolution as the SSP vector
    fprintf(fid, '%d \t\t\t\t\t\t\t! Number of receiver depths\n', numel(pars.depths));
    fprintf(fid, '0.00 %f /\t\t\t\t! Receiver point depth range [m]\n', pars.depths(end));
    fprintf(fid, '1001 \t\t\t\t\t! Number of receiver ranges\n');
    fprintf(fid, '0.00 %f /\t\t\t\t\t! Receiver range limits [km]\n', pars.maxrange*1e-3);
elseif strcmp(pars.simtype, 'arr') || strcmp(pars.simtype, 'eray')
    % For echo arrival simulation, use the given receiver depths and X positions
    fprintf(fid, '%d \t\t\t\t\t\t\t! Number of receiver depths\n', numel(pars.rxdepths));
    for n = 1:numel(pars.rxdepths)
        fprintf(fid, '%f ', pars.rxdepths(n));
    end
    fprintf(fid, '/ \t\t! Receiver depths [m]\n');
    fprintf(fid, '%d \t\t\t\t\t\t\t! Number of receiver ranges\n', numel(pars.rxranges));
    for n = 1:numel(pars.rxranges)
        fprintf(fid, '%f ', pars.rxranges(n)*1e-3);
    end
    fprintf(fid, '/ \t\t! Receiver ranges [km]\n');
else
    error('Simulation type not recognised. Options: ''arr'', ''loss'', ''ray'', ''eray''.')
end

% Before specifying the simulation type, determine if the receiver locations are specified as a
% rectilinear or irregular grid, i.e. simulate every combination or depth and range, or every pair of depth and range
if pars.regulargrid
    grid_spec = 'R';
else
    grid_spec = 'I';
end

% Determine the Geometric/Gaussian beam character
if pars.gaussianbeams
    beam_spec = 'B';
else
    beam_spec = 'G';
end

% Specify type of simulation
if strcmp(pars.simtype, 'loss')
    % Check if coherent or incoherent simulation is specified
    if pars.coherentloss
        fprintf(fid, ['''C', beam_spec, ' R', grid_spec, ''' \t\t\t\t\t\t! Coherent addition of echoes, geometric (G) or Gaussian (B) beams\n']);
    else
        fprintf(fid, ['''I', beam_spec, ' R', grid_spec, ''' \t\t\t\t\t\t! Incoherent addition of echoes, geometric (G) or Gaussian (B) beams\n']);
    end
elseif strcmp(pars.simtype, 'ray')
    fprintf(fid, ['''R', beam_spec, ' R', grid_spec, ''' '' \t\t\t\t\t\t! Ray tracing simulation, geometric (G) or Gaussian (B) beams\n']);
elseif strcmp(pars.simtype, 'eray')
    fprintf(fid, ['''E', beam_spec, ' R', grid_spec, ''' \t\t\t\t\t\t! Eigenray tracing simulation, geometric (G) or Gaussian (B) beams\n']);
elseif strcmp(pars.simtype, 'arr')
    fprintf(fid, ['''A', beam_spec, ' R', grid_spec, ''' \t\t\t\t\t\t! Echo arrivals simulation, geometric (G) or Gaussian (B) beams\n']); 
else
    error(['Unknown simulation type: ' pars.simtype]);
end

% Number of beams to be simulated
fprintf(fid, '%d \t\t\t\t\t\t\t! Number of rays to simulate\n', pars.numrays);

% Specify the departure angle range of the source signal rays
fprintf(fid, '%f %f /\t\t\t\t! Range of departure angles [degrees]\n', pars.minangle, pars.maxangle); 

% Finally, specify the depth and range boundaries to be simulated
fprintf(fid, '0.0 %f %f \t\t\t! Auto step size, depth limit [m], X axis limit [km]\n',...
             pars.depths(end), 1.01*pars.maxrange*1e-3); 

% Close the file output stream
fclose(fid);