function pars = default_sim_pars()
%DEFAULT_SIM_PARS returns a populated structure of simulation parameters
% with default values necessary to perform a simple ray trace simulation
% To perform other types of simulations, the fields of the output structure can be modified
%
%INPUTS:
% NONE
%
%OUTPUTS:
% PARS - structure of simulation parameters
%
%Complete list of the PARS structure fields:
% FILENAME - name/path for the BELLHOP output files
% TITLE - title of the simulation (used for default BELLHOP plotting functions)
% SIMTYPE - one of the following strings specifying the simulation type
%  'ray' - simple ray tracing
%  'eray' - Eigenray tracing 
%  'loss' - 2D propagation loss calculation
%  'arr' - arrivals simulation (outputs attenuation/delay/phase of received echoes)
% FREQ - frequency [Hz]
% DEPTHS - vector of depth for the sound speed profile (SSP)
% SOUNDSPEEDS - vector of sound speeds corresponding to each depth (SSP)
% MAXDEPTH - sea depth [m]
% MAXRANGE - maximum horizontal range to be simulated [m]
% SOURCEDEPTHS - vector (or single value) of source depths [m]
% RXDEPTHS - vector (or single value) of receiver depths [m]
% RXRANGES - vector (or single value) of receiver horizontal positions [m]
% REGULARGRID - if true, regular grid with every combination of receiver depth-range is simulated,
%               if false, irregular grid at every pair of receiver (depth, range) is simulated
% THORPABSORB - flag indicating if Thorp abosption loss should be included
% COHERENTLOSS - use coherent addition of the multipath components (including phase information)?
% GAUSSIANBEAMS - use Gaussian beams instead of hat-shaped beams?
% NUMRAYS - number of rays generated at the source
% MINANGLE - minimum angle of the ray fan [degrees]
% MAXANGLE - maximum angle of the ray fan [degrees]
% USE_ALTIMETRY - use a custom surface wave model instead of flat surface?
% WAVE_RESOLUTION - sampling interval for the surface waves [m]
% WIND_SPEED - wind speed for the Pierson-Moskowitz surface wave spectrum
% USE_BATHYMETRY - use custom bathymetry instead of a flat sea bed?
% HILL_LENGTH - length of a single hill for the bathymetry [m]
% MAX_HILL_HEIGHT - maximum hill height for the bathymetry [m]

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

% File name and the simulation title
pars.filename = 'simfiles/default_sim'; % do not include '.env' extension, as this name will be used for several file types
pars.title = '2D Ray Trace Example'; % (this will appear on the plots)

% Specify the simulation type as 'ray' by default, other options are:
%  'ray' - simple ray tracing
%  'eray' - Eigenray tracing 
%  'loss' - 2D propagation loss calculation
%  'arr' - arrivals simulation (outputs attenuation/delay/phase of received echoes)
pars.simtype = 'ray';

% Carrier frequency [Hz]
pars.freq = 24e3;

% Sound speed profile given by a vector of depths [m], and sound speeds [m/s]
% As an example, use the North Atlantic Ocean SSP with maximum depth of 500m
load('data/north_atl_ocean_ssp_sum.mat', 'c', 'z');
pars.maxdepth = 500;
pars.depths = 0:10:pars.maxdepth;
pars.soundspeeds = interp1(z, c, pars.depths); % we interpolate the SSP to 10m steps to have detailed BELLHOP simulations

% Maximum range [m] of the simulated area
pars.maxrange = 5e3;

% Source depth [m]
pars.sourcedepths = 200;

% Receiver depths and ranges
pars.rxdepths = pars.maxdepth/2;
pars.rxranges = pars.maxrange;

% Specify the flag which tells BELLHOP whether receiver locations need to be simulated
% at every (depth, range) combination, i.e. rectilinear grid, or at every (depth, range) pair
pars.regulargrid = true;

% No altimetry or bathymetry by default (flat surface and bottom)
pars.use_altimetry = false;
pars.use_bathymetry = false;

% Transmission loss parameters
pars.thorpabsorb = true; % Use Thorp absorption? (only used by 'loss' simulation type)
pars.coherentloss = false; % coherent/incoherent transmission loss (only used by 'loss' simulation type)
pars.gaussianbeams = false; % geometric beams by default (better for ray tracing plots)

% Small number of rays within [-15, 15] degrees departure angle range for a simple ray trace
pars.numrays = 21;
pars.minangle = -15;
pars.maxangle = 15;
