function [ ] = create_3d_channel_lut(src_pos, rx_pos, output_file, ... % compulsory arguments
                                     save_raw_imp_resp, ssp, water_depth, centre_freq, bandwidth, max_hill_height) % optional arguments
%CREATE_3D_CHANNEL_LUT function creates a CSV file with a channel model look-up table
% for every pair of nodes specified in the position matrices (first two inputs)
%COMPULSORY INPUTS:
% SRC_POS - [Nx3] matrix of XYZ source coordinates [m] (Z dimension is positive, e.g. 100 means 100m depth)
% RX_POS - [Nx3] matrix of XYZ receiver coordinates [m] (Z dimension is positive, e.g. 100 means 100m depth)
% OUTPUT_FILE - string containing the name of the output CSV file
%OPTIONAL INPUTS:
% SAVE_RAW_IMP_RESP - save raw impulse responses or processed channel data to file?
% SSP - structure containing two vectors: DEPTHS [m] and SPEEDS [m/s],
%       by default the North Atlantic Ocean SSP from the paper is used
% WATER_DEPTH - sea depth [m]
% CENTRE_FREQ - centre frequency [Hz]
% BANDWIDTH - bandwidth [Hz]
% MAX_HILL_HEIGHT - maximum hill height for the bathymetry [m]
%
%OUTPUTS:
% CSV file is created at the specified path (third input)

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

% By default use ther North Atlantic SSP plotted in the paper
if (nargin < 5) || isempty(ssp)
    load('data/north_atl_ocean_ssp_sum.mat', 'c', 'z');
    ssp.depths = z;
    ssp.speeds = c;
end
% Other default parameter values
if (nargin < 4) || isempty(save_raw_imp_resp); save_raw_imp_resp = false; end
if (nargin < 6) || isempty(water_depth); water_depth = 500; end
if (nargin < 7) || isempty(centre_freq); centre_freq = 24e3; end
if (nargin < 8) || isempty(bandwidth); bandwidth = 7.2e3; end
if (nargin < 9) || isempty(max_hill_height); max_hill_height = 10; end

% Add multipath components coherently?
coherent_multipath = true; % true - full multipath fading model, false - total power of all multipath components

% Only the echoes that constitute the below proportion of total energy are included
% This is important for the raw impulse response output to eliminate very weak multipath components that
% take up most of the CSV file content (huge file size, negligible effect on the channel)
multipath_cutoff = 0.95; % 95% of total Rx energy

% Use the centre frequency for the BELLHOP simulations
pars.freq = centre_freq;

% Specify the simulation type and title
pars.simtype = 'arr';
pars.title = 'Channel LUT';

% In this function use an irregular grid, i.e. simulate receivers only at every (depth, range) pair
pars.regulargrid = false;

% File name and the simulation title
pars.filename = 'simfiles/channel_lut'; % temporary directory for BELLHOP generated files

% Interpolate the SSP to 10m steps to have detailed BELLHOP simulations
pars.maxdepth = water_depth;
pars.depths = 0:10:pars.maxdepth;
pars.soundspeeds = interp1(ssp.depths, ssp.speeds, pars.depths);

% Set random number generator seed for reproducible altimetry/bathymetry
rng(12453);

% Altimetry parameters
pars.use_altimetry = true; % if false, then flat surface is simulated
pars.wave_resolution = 20; % sampling point interval for surface waves
pars.wind_speed = 10; % 10 m/s wind

% Bathymetry parameters
pars.use_bathymetry = true;
pars.hill_length = 200; % 200m long hills
pars.max_hill_height = max_hill_height; % maximum hill height

% Specify a large number of Gaussian beams and the full range of departure angles at the source
pars.numrays = 10001;
pars.minangle = -90;
pars.maxangle = 90;
pars.gaussianbeams = true;

% Open a file output stream and write the header line depending on type of output (raw/processed)
fid = fopen(output_file, 'w');
if save_raw_imp_resp
    fprintf(fid, 'SRC_INDEX,RX_INDEX,GAIN,PH_SHIFT,DELAY\n');
else
    fprintf(fid, 'SRC_INDEX,RX_INDEX,CH_GAIN,CH_DELAY,SPREAD\n');
end

% Loop through every source position in the input array, and simulate BELLHOP 
% using the Rx depths and ranges of all receiver nodes relative to the source
num_src_nodes = size(src_pos, 1);
for src = 1:num_src_nodes
    
    % Set the source depth for the BELLHOP simulation
    pars.sourcedepths = src_pos(src, 3);
    
    % Find the absolute distance between the source and every receiver position
    src2rx_dist = sqrt( (src_pos(1) - rx_pos(:, 1)).^2 + (src_pos(2) - rx_pos(:, 2)).^2 + (src_pos(3) - rx_pos(:, 3)).^2 );
    % Create a vector of receiver indices, excluding those co-located with the source (if any)
    rx_ind = find(src2rx_dist > 1e-3);
    
    % Determine receiver ranges relative to the source position
    rx_ranges = sqrt( (rx_pos(rx_ind, 1) - src_pos(src, 1)).^2 + (rx_pos(rx_ind, 2) - src_pos(src, 2)).^2 );
    rx_ranges = max(rx_ranges, 1); % set range to at least 1m, BELLHOP does not work for zero ranges
    pars.maxrange = max(rx_ranges);
    
    % Since BELLHOP ends up sorting the input ranges anyway, sort the receivers by range
    [pars.rxranges, sort_ind] = sort(rx_ranges);
    
    % BELLHOP does not accept non-monotonically increasing range
    % If two ranges happen to be identical to millimetre precision, add 2mm to the second one to avoid conflict
    while any(pars.rxranges(1:end-1) >= pars.rxranges(2:end)-1e-3)
        % Find which ranges clash, i.e. break monotonic order
        clashing_ranges = find(pars.rxranges(1:end-1) >= pars.rxranges(2:end)-1e-3);
        pars.rxranges(clashing_ranges+1) = pars.rxranges(clashing_ranges+1) + 2e-3;
    end
    
    % Set receiver depths taking into account the range-based sorting order
    pars.rxdepths = rx_pos(rx_ind(sort_ind), 3)';
    
    % If altimetry and/or bathymetry need to be simulated, create ATI/BTY files
    if pars.use_altimetry
        create_sea_surface_file(pars);
    end
    if pars.use_bathymetry
        create_rand_bty_file(pars);
    end
    
    % Create the BELLHOP ENV file using the given parameters
    create_bellhop_env_file(pars);

    % Run BELLHOP
    bellhop(pars.filename);
    
    % Extract all impulse responses from the output file
    imp_resp = process_arr_file(pars.filename, pars.regulargrid);
    
    % Loop through all receiver positions and write a line in the output file for each
    for k = 1:numel(rx_ind)
            
        % Write source and receiver index
        fprintf(fid, '%d,%d', src, rx_ind(sort_ind(k)));
        
        % Compress the impulse response by only including strongest echoes up to a cutoff point
        comp_imp_resp = compress_imp_resp(imp_resp{k}, multipath_cutoff);
        
        % If the raw data needs to be saved, do not do any further processing
        if save_raw_imp_resp
            
            % Loop through every echo and store its attenuation, phase shift and propagation delay
            for echo = 1:comp_imp_resp.num_echoes
                fprintf(fid, ',%0.2f,%0.4f,%0.4f', 20.*log10(comp_imp_resp.ampl(echo)), ...
                    comp_imp_resp.phase_shift(echo), comp_imp_resp.delay(echo));
            end
            
        % Otherwise, process the impulse response and only save the channel gain and delay
        else
            % Calculate channel gain [dB], delay [s] and delay spread
            [ch_gain, ch_delay, delay_spread] = process_imp_resp(comp_imp_resp, centre_freq, bandwidth,...
                                                                 mean(pars.soundspeeds), coherent_multipath);
            % Write them to the output file
            fprintf(fid, ',%0.2f,%0.4f,%0.4f', ch_gain, ch_delay, delay_spread);                                             
        end
        
        % End of line for this source and receiver combination
        fprintf(fid, '\n');
            
    end
    
    % Display progress
    disp(['     Source ' num2str(src) '/' num2str(num_src_nodes) ' simulated.']);
    
end
