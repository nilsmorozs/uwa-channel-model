% This script plots the results of the STDMA simulations

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

%% Load the results
txp_ssp_combs = {{155, 'jul'}, {160, 'jan'}, {160, 'jul'}, {165, 'jan'}, {165, 'jul'}, {170, 'jan'}};
slot_length_data = cell(numel(txp_ssp_combs));
frame_length_data = cell(numel(txp_ssp_combs));
throughput_data = cell(numel(txp_ssp_combs));
for k = 1:numel(txp_ssp_combs)
    
    % Load the data
    load(['data/res-' num2str(txp_ssp_combs{k}{1}) 'dB-' txp_ssp_combs{k}{2} '.mat'],...
                  'slot_lengths', 'frame_lengths', 'num_nodes');
    % Store slot and frame lengths
    slot_length_data{k} = slot_lengths;
    frame_length_data{k} = frame_lengths;
    % Calculate network throughput
    num_packets = num_nodes*(num_nodes-1)/2;
    throughput_data{k} = num_packets ./ (slot_lengths .* frame_lengths);

end

%% Plot the results

% Set up the legend and the line types
line_styles = {'k--', 'k-', 'r--', 'r-', 'b--', 'b-'};
legends = {'Jul: 155 dB', 'Jan: 160 dB', 'Jul: 160 dB', ...
           'Jan: 165 dB', 'Jul: 165 dB', 'Jan: 170 dB'};

% Plot the CDFs of the slot lengths
figure; hold on;
for k = 1:numel(txp_ssp_combs)
    h = cdfplot(slot_length_data{k});
    set(h, 'linewidth', 1.5, 'color', line_styles{k}(1), 'linestyle', line_styles{k}(2:end));
end
% Format the axis and legend
title('');
xlabel('Slot duration, sec'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'Source level, SSP');
legend('boxon');
% 
% Plot the CDFs of the frame lengths
figure; hold on;
for k = 1:numel(txp_ssp_combs)
    h = cdfplot(frame_length_data{k});
    set(h, 'linewidth', 1.5, 'color', line_styles{k}(1), 'linestyle', line_styles{k}(2:end));
end
% Format the axis and legend
title('');
xlabel('Number of slots per frame'); ylabel('CDF');
box on; grid off;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'SSP, source level');
legend('boxon');

% Plot the CDFs of the frame duration
figure; hold on;
for k = 1:numel(txp_ssp_combs)
    h = cdfplot(slot_length_data{k}.*frame_length_data{k});
    set(h, 'linewidth', 1.5, 'color', line_styles{k}(1), 'linestyle', line_styles{k}(2:end));
end
% Format the axis and legend
title('');
xlabel('Frame duration, sec'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'Source level, SSP');
legend('boxon');

% Plot the CDFs of the throughput
figure; hold on;
for k = 1:numel(txp_ssp_combs)
    h = cdfplot(throughput_data{k});
    set(h, 'linewidth', 1.5, 'color', line_styles{k}(1), 'linestyle', line_styles{k}(2:end));
end
% Format the axis and legend
title('');
xlabel('Throughput, packets/sec'); ylabel('CDF');
box on; grid off;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'SSP, source level');
legend('boxon');