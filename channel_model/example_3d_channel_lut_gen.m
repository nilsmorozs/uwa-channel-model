% This script gives an example of creating a CSV file with channel data obtained via BELLHOP simulations
% for arbitrary node positions in 3D space, using the CREATE_3D_CHANNEL_LUT
%
% This script was used top generate the channel data for the Riverbed Modeler case study

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

% Specify the type of output required: 
%    - raw impulse response where amplitude, phase and delay of all echoes are saved to the CSV file
%    - pre-processed channel model, with only the channel gain [dB], propagation delay and multipath spread of every link
save_raw_imp_resp = false; % true - raw impulse response data, false - channel gain, delay and spread

% Set random seed for reproducibility
rng(12357);

% Create a random matrix of node XYZ positions (depth is positive) in a 6km x 6km x 500m box
num_nodes = 31; % 31 nodes (one surface node)
min_depth = 10; % set minimum depth safely below the maximum surface amplitude
max_depth = 480; % set maximum depth above our 10m high sinusoidal bathymetry
max_range = 6e3; % maximum range 6 km
node_pos = [max_range/2, max_range/2, 10; % surface node in the middle of the coverage area...
            rand([num_nodes-1 2]).*max_range, min_depth + rand([num_nodes-1 1]).*(max_depth-min_depth)]; % 50 other nodes

% Choose the name of the output CSV files for storing node positions and channel data
node_pos_file = 'data/node_pos.csv';
output_file = 'data/3d_channel_data.csv';

%% Save node positions to CSV file, for use in external network simulators if needed
% Write header line % file name to store node positions
fid = fopen(node_pos_file, 'w');
fprintf(fid, 'INDEX,XPOS,YPOS,DEPTH\n');
fclose(fid);
% Create column vector of node indices
node_ind_column = (1:num_nodes)';
% Append the node positions and indices to the CSV file
dlmwrite(node_pos_file, [node_ind_column, node_pos], '-append', 'delimiter', ',');

%% Run BELLHOP simulations using every node as the source and save results in a CSV file
create_3d_channel_lut(node_pos, node_pos, output_file, save_raw_imp_resp);