function [impulse_resp] = process_arr_file(filename, regular_grid)
%PROCESS_ARR_FILE function processes the 'arr' file and returns 
% the impulse response (amplitude, delay and phase shift vectors) between every source and receiver
%
%INPUTS:
% FILENAME - string containing the name of the .arr file
% REGULAR_GRID - flag indicating whether a regular or irregular grid was simulated
%
%OUTPUTS:
% IMPULSE_RESP - cell array of impulse response structures for every Tx-Rx pair

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

% If the second argument is not specified, assume a regular grid
if nargin < 2
    regular_grid = true;
end

% Check that the input filename has ".arr" extension, and add it if needed
if ~strcmp(filename(end-3:end), '.arr')
    filename = [filename, '.arr'];
end

% Open a file input stream
fid = fopen(filename, 'r');

% Read the first line of the text file and save number of source depths, rx depths and rx ranges
line = fgets(fid);
vals = str2num(line);
num_source_depths = vals(2);
num_rx_depths = vals(3);
num_rx_ranges = vals(4);

% If an irregular grid is simulated, set number of Rx ranges to 1, as each of them was paired up with an Rx depth
if ~regular_grid
    num_rx_ranges = 1;
end

% Preallocate the output arrays now that we know their intended size
impulse_resp = cell(num_source_depths, num_rx_depths, num_rx_ranges);

% Read and discard the next 3 lines (they state parameters that we already know)
for n = 1:3
    fgets(fid);
end

% The rest of the text file lists the echoes for every source-receiver pair
% Loop through every source depth, receiver depth, receiver range
for sd = 1:num_source_depths
    % Discard a line that tells us the maximum number of echoes for this source depth
    fgets(fid);
    for rxd = 1:num_rx_depths
        for rxr = 1:num_rx_ranges
            
            % The first line states the total number of echoes received
            line = fgets(fid);
            h.num_echoes = str2num(line);
            
            % Analyse this source-receiver pair only if any echoes have been received
            if h.num_echoes > 0           
                % Loop through every echo and note their amplitude, phase and propagation delay
                h.ampl = NaN(1, h.num_echoes);
                h.phase_shift = NaN(1, h.num_echoes);
                h.delay = NaN(1, h.num_echoes);
                h.ntb = NaN(1, h.num_echoes); % number of top bounces
                h.nbb = NaN(1, h.num_echoes); % number of bottom bounces
                for n = 1:h.num_echoes
                    line = fgets(fid);
                    vals = str2num(line);
                    if numel(vals) < 3
                        error('Unexpected ARR file format: too few elements in a line');
                    end
                    % Save the impulse response as amplitude, delay, phase vectors
                    h.ampl(n) = vals(1);
                    h.phase_shift(n) = deg2rad(vals(2));
                    h.delay(n) = vals(3);
                    % Also save the number of top and bottom bounces for filtering
                    h.ntb(n) = vals(7);
                    h.nbb(n) = vals(8);
                end
            end
            
            % Save the echo information in the overall array
            impulse_resp{sd, rxd, rxr} = h;
            
        end
    end
end

% Close the file input stream
fclose(fid);

end