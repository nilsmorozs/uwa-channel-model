% This script creates a lookup-table of channel impulse responses obtained via BELLHOP simulations
% for a grid of receiver positions

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

%% Set up the parameters for the BELLHOP simulations

% The MATLAB function that creates a BELLHOP ENV file requires a 'pars'
% structure with pre-defined fields, that are populated with default values by the function below
pars = default_sim_pars;

% 200m depth, 600m range, flat SSP, hard granite bottom
pars.maxdepth = 300;
pars.maxrange = 1500;
pars.depths = 0:pars.maxdepth;
pars.soundspeeds = 1500.0 .* ones(1, numel(pars.depths));
pars.bsp = 4000; % 4000 m/s speed in granite? :)
pars.bdensity = 3.0; % 3x the density of sandsilt? Should be very reflective

% Sinusoidal cave characteristics
cave_bend_ranges = [600, 850, 1150]-1;
cave_height = 102;

% Specify the simulation type, as the 'arrivals' simulation:
pars.simtype = 'arr';

% File name and the simulation title
output_file = 'data/angled_cave2_grid_data.csv';
pars.filename = 'simfiles/grid_lut_sim'; % temporary directory for large BELLHOP ENV files

% Use Gaussian beams for more realistic channel calculations
pars.gaussianbeams = true;

% Set random number generator seed for reproducible altimetry/bathymetry
rng(12453);

% Cave altimetry + bathymetry
pars.use_altimetry = true;
pars.use_bathymetry = true;
[bty_x, bty_y, topbound_x, topbound_y] = create_angled_cave_ati_bty(pars, cave_height, cave_bend_ranges);

% Save altimetry and bathymetry in a file with same name as the data
save([extractBefore(output_file, '.'), '_bty_ati.mat'], 'topbound_x', 'topbound_y', 'bty_x','bty_y')

% Specify the source depths to be simulated
source_depth_vect = [50];
num_source_depths = numel(source_depth_vect);

% Specify a grid of receiver depths and ranges to be simulated
rx_depth_vect = 0:10:pars.maxdepth;
rx_range_vect = [1, 10:10:pars.maxrange]; % range (start at 1m, as BELLHOP returns zero echoes for receivers located at 0m range)
num_rx_depths = numel(rx_depth_vect);
num_rx_ranges = numel(rx_range_vect);

% Every BELLHOP simulation will include the full set of Rx depths and ranges
pars.rxdepths = rx_depth_vect;
pars.rxranges = rx_range_vect;

% Specify a large number of rays (>2000) and the -90-90 departure angle range at the source
pars.numrays = 10001;
pars.minangle = -90;
pars.maxangle = 90;

%% Perform the BELLHOP simulations for all combinations of Src-Rx positions and store the results

% Open a file output stream and write the header line
fid = fopen(output_file, 'w');
fprintf(fid, 'SRC_DEPTH,RX_DEPTH,RX_RANGE,GAIN,PH_SHIFT,DELAY\n');

% Loop through every source position, and run BELLHOP for all Rx positions
% We could also run a single BELLHOP simulation for all source positions, 
% but a normal computer may run out of memory for it
for n = 1:num_source_depths

    % Extract the source depth for this simulation
    pars.sourcedepths = source_depth_vect(n);
    pars.maxrange = max(rx_range_vect);

    % Create the BELLHOP ENV file using the given paramaters
    create_bellhop_env_file(pars);

    % Run BELLHOP
    bellhop(pars.filename);
    
    % Extract impulse responses from the output file
    imp_resp = process_arr_file(pars.filename);
    for k = 1:size(imp_resp, 2)
        for m = 1:size(imp_resp, 3)
            
            % Write source and receiver depth and range into the CSV line
            fprintf(fid, '%0.1f,%0.1f,%0.1f', source_depth_vect(n), rx_depth_vect(k), rx_range_vect(m));
            % Compress the impulse response by only including strongest echoes comprising 99% of the energy
            comp_imp_resp = compress_imp_resp(imp_resp{1, k, m}, 0.95);
            % Loop through every echo and store its attenuation, phase shift and propagation delay
            for echo = 1:comp_imp_resp.num_echoes
                fprintf(fid, ',%0.2f,%0.4f,%0.4f', 20.*log10(comp_imp_resp.ampl(echo)), ...
                                                    comp_imp_resp.phase_shift(echo), comp_imp_resp.delay(echo));
            end
            % End of line for this source and receiver combination
            fprintf(fid, '\n');
            
        end
    end
    
    % Display progress
    disp(['Source depth of ' num2str(pars.sourcedepths) 'm simulated.']);
    
end

% Close the file output stream
fclose(fid);
