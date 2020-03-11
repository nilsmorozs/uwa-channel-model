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
txp_vals = [160, 165, 170];
ssp_months = {'jan', 'jul'};
slot_length_data = cell(numel(txp_vals), numel(ssp_months));
frame_length_data = cell(numel(txp_vals), numel(ssp_months));
throughput_data = cell(numel(txp_vals), numel(ssp_months));
for m = 1:numel(txp_vals)
    for k = 1:numel(ssp_months)
        load(['data/res-' num2str(txp_vals(m)) 'dB-' ssp_months{k} '.mat']);
        % Store slot and frame lengths
        slot_length_data{m, k} = slot_lengths;
        frame_length_data{m, k} = frame_lengths;
        % Calculate network throughput
        num_packets = num_nodes*(num_nodes-1)/2;
        throughput_data{m, k} = num_packets ./ (slot_lengths .* frame_lengths);
    end
end

%% Plot the results

% Set up the legend and the line types
line_styles = {'k-', 'k--', 'b-', 'b--', 'r-', 'r--'};
legends = {'160 dB, Jan', '160 dB, Jul', ...
           '165 dB, Jan', '165 dB, Jul', ...
           '170 dB, Jan', '170 dB, Jul'};

% Plot the CDFs of the slot lengths
figure; hold on;
index = 1;
for m = 1:numel(txp_vals)
    for k = 1:numel(ssp_months)
        h = cdfplot(slot_length_data{m, k});
        set(h, 'linewidth', 1.5, 'color', line_styles{index}(1), 'linestyle', line_styles{index}(2:end));
        index = index + 1;
    end
end
% Format the axis and legend
title('');
xlabel('Slot duration, sec'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'Source level, SSP');
legend('boxon');

% Plot the CDFs of the frame lengths
figure; hold on;
index = 1;
for m = 1:numel(txp_vals)
    for k = 1:numel(ssp_months)
        h = cdfplot(frame_length_data{m, k});
        set(h, 'linewidth', 1.5, 'color', line_styles{index}(1), 'linestyle', line_styles{index}(2:end));
        index = index + 1;
    end
end
% Format the axis and legend
title('');
xlabel('Number of slots per frame'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'Source level, SSP');
legend('boxoff');

% Plot the CDFs of the frame duration
figure; hold on;
index = 1;
for m = 1:numel(txp_vals)
    for k = 1:numel(ssp_months)
        h = cdfplot(slot_length_data{m, k}.*frame_length_data{m, k});
        set(h, 'linewidth', 1.5, 'color', line_styles{index}(1), 'linestyle', line_styles{index}(2:end));
        index = index + 1;
    end
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
index = 1;
for m = 1:numel(txp_vals)
    for k = 1:numel(ssp_months)
        h = cdfplot(throughput_data{m, k});
        set(h, 'linewidth', 1.5, 'color', line_styles{index}(1), 'linestyle', line_styles{index}(2:end));
        index = index + 1;
    end
end
% Format the axis and legend
title('');
xlabel('Throughput, packets/sec'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'Source level, SSP');
legend('boxon');