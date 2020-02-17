function process_raw_ch_model(in_file, out_file, centre_freq, bandwidth, mean_sp, coherent_multipath)
%PROCESS_RAW_CH_MODEL reads in a CSV file with a raw channel model, processes every impulse response and
% creates a different CSV file with a processed channel model (only attenuation, delay and delay spread for every link)
%
%INPUTS:
% IN_FILE - name of the input CSV file (raw channel model)
% OUT_FILE - name of the output csv file (processed channel model)
% CENTRE_FREQ - centre frequency [Hz]
% BANDWIDTH - bandwidth [Hz]
% COHERENT_MULTIPATH - flag indicating whether echoes should be added coherently or ignoring the phase
% MEAN_SP - mean sound speed [m/s], needed for calculating the absorption loss
%
%OUTPUTS:
% NONE (a CSV file is created)

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

% Check number of inputs and define some default values
if nargin < 4
    % Force at least 4 arguments
    error('At least 4 input arguments are needed: input and output file, centre frequency and bandwidth');
end
if nargin < 5
    % North Atlantic summer SSP by default (used in the examples)
    load('data/north_atl_ocean_ssp_sum.mat', 'z', 'c');
    ssp_depths = 0:10:500;
    ssp = interp1(z, c, ssp_depths);
    mean_sp = mean(ssp);
end
if nargin < 6
    % Coherent multipath addition by default
    coherent_multipath = true;
end

% Read the input CSV file with the raw channel model data
in_csv_data = csvread(in_file, 1, 0);

% Open a file output stream and write the header line
fid = fopen(out_file, 'w');
fprintf(fid, 'SRC_INDEX,RX_INDEX,CH_GAIN,CH_DELAY,SPREAD\n');

% Loop through every line in the input data, process the impulse response and write a line to the output file
for l = 1:size(in_csv_data, 1)
    
    % Take a row out of the CSV data
    csv_row = in_csv_data(l, :);
    
    % Take out the columns with padded zero entries (where amplitude and delay are zero due to variable number of echoes)
    first_padded_echo = find( (csv_row(3:3:end-2)==0) & (csv_row(5:3:end)==0), 1, 'first');
    csv_row(3 + 3*(first_padded_echo-1) : end) = [];
    
    % From this row, read the amplitudes, phase shifts and delays of all echoes
    imp_resp.ampl = 10 .^ (csv_row(3:3:end-2) ./ 20);
    imp_resp.phase_shift = csv_row(4:3:end-1);
    imp_resp.delay = csv_row(5:3:end);
    imp_resp.num_echoes = numel(imp_resp.delay);
    
    % Calculate the channel gain and delay from the impulse response
    [ch_gain, ch_delay, delay_spread] = process_imp_response(imp_resp, centre_freq, bandwidth, coherent_multipath, mean_sp);
    
    % Write a line to the output file
    fprintf(fid, '%d,%d,%0.2f,%0.4f,%0.4f\n', csv_row(1), csv_row(2), ch_gain, ch_delay, delay_spread);
end