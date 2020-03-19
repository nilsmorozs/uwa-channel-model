% This script runs a single BELLHOP simulation and produces a transmission loss plot

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

%% This part of the script sets up the simulation parameters of a BELLHOP run

% The MATLAB function that creates a BELLHOP ENV file requires a 'pars'
% structure with pre-defined fields, that are populated with default values by the function below
pars = default_sim_pars;

% File name, simulation title and type
pars.filename = 'simfiles/tx_loss_north_sea'; % do not include '.env' extension, as this name will be used for several file types
pars.title = 'Tx Loss in the North Sea'; % (this will appear on the plots)
pars.simtype = 'loss';

% Load the North Sea SSP (choose 'jan' or 'jul' for month)
month = 'jul';
load(['data/north_sea_ssp_' month '.mat']);
ssp.depths = z;
ssp.speeds = c;
sea_depth = 70;

% Interpolate the SSP to have more detailed BELLHOP simulations
num_ssp_points = 50;
pars.maxdepth = sea_depth;
pars.depths = linspace(0, pars.maxdepth, num_ssp_points);
pars.soundspeeds = interp1(ssp.depths, ssp.speeds, pars.depths);

% Carrier frequency [Hz]
pars.freq = 24e3;

% Source depth [m]
pars.sourcedepths = 65;

% Maximum range for the simulation
pars.maxrange = 3e3;

% Thorp absorption and Gaussian beams (for more accurate Tx loss calculation)
pars.thorpabsorb = true;
pars.gaussianbeams = true;

% Set random number generator seed for reproducible altimetry/bathymetry
rng(124537);

% Altimetry parameters
pars.use_altimetry = true; % if false, then flat surface is simulated
pars.wave_resolution = 10; % 10 m resolution for surface waves
pars.wind_speed = 10; % 10 m/s wind
if pars.use_altimetry
    create_sea_surface_file(pars);
end

% Bathymetry parameters
pars.use_bathymetry = true;
pars.hill_length = 200; % 200m long hills
pars.max_hill_height = 2; % 10m maximum hill height
if pars.use_bathymetry
    create_rand_bty_file(pars);
end

% Simulate a large number of rays at the full [-90, 90] angle range
pars.minangle = -90;
pars.maxangle = 90;
pars.numrays = 10001;

% Create the BELLHOP ENV file using the given paramaters
create_bellhop_env_file(pars);

%% Run BELLHOP using the ENV file that was created
bellhop(pars.filename);

%% Plot the results

% POlot transmission loss using the standard BELLHOP function
f = figure;
plotshd([pars.filename '.shd']); % this needs to have '.shd' file extension
c = colorbar('EastOutside');
c.Label.String = 'Transmission loss, dB';
c.Label.FontSize = 11;
caxis([30 80]);
grid on; box on;

% Plot the surface waves and bathymetry on top
% Plot surface wave coordinates from the ATI file (2 header lines, tab delimited)
if pars.use_altimetry
    hold on;
    plotati(pars.filename);
end
% Plot bottom coordinates from the BTY file (2 header lines, tab delimited)
if pars.use_bathymetry
    hold on;
    plotbty(pars.filename);
end
