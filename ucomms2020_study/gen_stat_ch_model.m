% This script creates a statistical channel model for the 10-node linear network
% obtained via BELLHOP simulations with small-scale variation in node positions

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

% Set random seed for reproducibility
rng(12357);

% Choose the name prefix of the output CSV file for storing the channel data
csv_file_prefix = 'data/ch_data-';

% Set up the system parameters
num_sensor_nodes = 10; % 10 sensor nodes in addition to one sink node 
inter_node_dist = 1e3; % distance between adjacent nodes
node_depth = 45; % nodes located near the sea bottom
sea_depth = 50; % maximum sea depth
max_hill_height = 2; % "hilly" bathymetry up to 2m
movement_rad = 2.5; % random node movement within a 5m diameter sphere
num_rand_pos = 50; % 50 random displacements in both source and receiver positions
centre_freq = 24e3; % centre frequency [Hz]
bandwidth = 7.2e3; % bandwidth [Hz]

% Load and store the SSP data from both files
max_depth = 50; % maximum depth
load('data/north_sea_ssp_jan.mat');
jan_ssp.depths = z(z <= sea_depth);
jan_ssp.speeds = c(z <= sea_depth);
load('data/north_sea_ssp_jul.mat');
jul_ssp.depths = z(z <= sea_depth);
jul_ssp.speeds = c(z <= sea_depth);

%% Run all BELLHOP simulations and save results in a CSV file

% Create an array of node positions for 1-10 hop distance
avg_src_pos = [0, 0, node_depth];
rx_pos_mat = [inter_node_dist.*(1:num_sensor_nodes)', ... % increasing X position
              zeros(num_sensor_nodes, 1), ... % constant Y position
              node_depth.*ones(num_sensor_nodes, 1)]; % constant depth

% Loop through every number of hops (1 - number of sensor nodes)
for n = 1:num_sensor_nodes
    
    % Note the hop distance being simulated
    disp(['Simulating ' num2str(n) ' hop distance...'])

    % Choose the average position of the receiver and the radius of the sphere of their movement
    avg_rx_pos = rx_pos_mat(n, :);

    % Generate positions for both source and receiver with random displacements
    rand_rad = movement_rad.*rand([num_rand_pos, 2]); % random uniform radius 
    rand_azim = 2.*pi.*rand([num_rand_pos, 2]); % random azimuth between 0 and 2*pi
    rand_elev = pi.*(rand([num_rand_pos, 2])-0.5); % random elevation between -pi/2 and pi/2
    [x, y, z] = sph2cart(rand_azim(:, 1), rand_elev(:, 1), rand_rad(:, 1)); % transform to Cartesian
    src_pos = repmat(avg_src_pos, [num_rand_pos, 1]) + [x, y, z];
    [x, y, z] = sph2cart(rand_azim(:, 2), rand_elev(:, 2), rand_rad(:, 2)); % transform to Cartesian
    rx_pos = repmat(avg_rx_pos, [num_rand_pos, 1]) + [x, y, z];

    % Run BELLHOP using the January SSP
    disp('  January SSP...')
    csv_file = [csv_file_prefix, 'jan-', num2str(n), 'hop.csv'];
    create_3d_channel_lut(src_pos, rx_pos, csv_file, false, jan_ssp, sea_depth,...
                                    centre_freq, bandwidth, max_hill_height);
                                
    % Run BELLHOP using the July SSP
    disp('  July SSP...')
    csv_file = [csv_file_prefix, 'jul-', num2str(n), 'hop.csv'];
    create_3d_channel_lut(src_pos, rx_pos, csv_file, false, jan_ssp, sea_depth,...
                                    centre_freq, bandwidth, max_hill_height);
end