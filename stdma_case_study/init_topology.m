function [intf_map, prop_delays, delay_spreads] = init_topology(num_nodes, tx_power, intf_snr, rand_seed)
%INIT_topology function fetches random channel samples from CSV files and 
% generates the interference map and propagation delay matrices
%
%INPUTS:
% NUM_NODES - number of nodes
% TX_POWER - source power [dB re uPa^2 m^2]
% INTF_SNR - SNR threshold for a packet to be considered interference [dB]
% RAND_SEED - random seed
%
%OUTPUTS:
% INTF_MAP - [NxN] interference matrix
% PROP_DELAYS - [NxN] propagation delay matrix [s]
% DELAY_SPREADS - [NxN] matrix of multipath delay spreads [s]

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

% Default input parameter values
if nargin < 1; num_nodes = 11; end
if nargin < 2; tx_power = 160; end
if nargin < 3; intf_snr = 0; end
if nargin < 4; rand_seed = 1; end

% Set the random seed
rng(17401*rand_seed);

% Calculate the ambient noise power
centre_freq = 24e3;
bandwidth = 7.2e3;
ship_act = 0.5;
wind_speed = 10;
noise = calc_ambient_noise(centre_freq, bandwidth, ship_act, wind_speed);

% Initialize the channel gains, delays and delay spreads
ch_gains = NaN(num_nodes);
prop_delays = NaN(num_nodes);
delay_spreads = NaN(num_nodes);

% Loop through every pair of nodes and fetch a channel sample for it at random
for n = 1:num_nodes
    for k = n+1:num_nodes
        
        % Fetch a random channel realization for this number of hops
        num_hops = abs(n-k);
        csv_file = ['data/stat_ch_data_linnet-' num2str(num_hops), 'hop.csv'];
        csv_data = csvread(csv_file, 1, 2);
        num_ch_samples = size(csv_data, 1);
        rand_row = csv_data(randi(num_ch_samples), :);
        
        % Save these channel characteristics in the matrix
        ch_gains(n, k) = rand_row(1); ch_gains(k, n) = rand_row(1);
        prop_delays(n, k) = rand_row(2); prop_delays(k, n) = rand_row(2);
        delay_spreads(n, k) = rand_row(3); delay_spreads(k, n) = rand_row(3);
    end
end

% Calculate received signal SNR for every pair of nodes
snr_mat = tx_power + ch_gains - noise;

% Flag the links with SNR above the threshold in the interference map
intf_map = false(num_nodes);
intf_map(snr_mat >= intf_snr) = true;

% Make the interference map symmetrical (interference the same both ways)
intf_map = intf_map | intf_map';