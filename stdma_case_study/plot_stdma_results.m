% This script plots the results of the STDMA case study simulation results

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
load('data/res-160dB.mat');
slot_lengths_160 = slot_lengths;
frame_lengths_160 = frame_lengths;
load('data/res-165dB.mat');
slot_lengths_165 = slot_lengths;
frame_lengths_165 = frame_lengths;
load('data/res-170dB.mat');
slot_lengths_170 = slot_lengths;
frame_lengths_170 = frame_lengths;

% Calculate network throughput
num_packets = num_nodes*(num_nodes-1)/2;
throughput_160 = num_packets ./ (slot_lengths_160 .* frame_lengths_160);
throughput_165 = num_packets ./ (slot_lengths_165 .* frame_lengths_165);
throughput_170 = num_packets ./ (slot_lengths_170 .* frame_lengths_170);

%% Plot the results

% Set up the legend and the line types
line_styles = {'r-.', 'b-', 'k--'};
legends = {'160 dB', '165 dB', '170 dB'};

% Plot the CDF of the slot lengths
figure; hold on;
h = cdfplot(slot_lengths_160);
set(h, 'linewidth', 1.5, 'color', line_styles{1}(1), 'linestyle', line_styles{1}(2:end));
h = cdfplot(slot_lengths_165);
set(h, 'linewidth', 1.5, 'color', line_styles{2}(1), 'linestyle', line_styles{2}(2:end));
h = cdfplot(slot_lengths_170);
set(h, 'linewidth', 1.5, 'color', line_styles{3}(1), 'linestyle', line_styles{3}(2:end));
% Format the axis and legend
title('');
xlabel('Slot duration, sec'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends, 'Location', 'SouthEast');
title(leg, 'Source level');
legend('boxoff');

% Plot the CDF of the frame lengths
figure; hold on;
h = cdfplot(frame_lengths_160);
set(h, 'linewidth', 1.5, 'color', line_styles{1}(1), 'linestyle', line_styles{1}(2:end));
h = cdfplot(frame_lengths_165);
set(h, 'linewidth', 1.5, 'color', line_styles{2}(1), 'linestyle', line_styles{2}(2:end));
h = cdfplot(frame_lengths_170);
set(h, 'linewidth', 1.5, 'color', line_styles{3}(1), 'linestyle', line_styles{3}(2:end));
% Format the axis and legend
title('');
xlabel('Number of slots per frame'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends);
title(leg, 'Source level');
legend('boxoff');

% Plot the CDF of the network throughput
figure; hold on;
h = cdfplot(throughput_160);
set(h, 'linewidth', 1.5, 'color', line_styles{1}(1), 'linestyle', line_styles{1}(2:end));
h = cdfplot(throughput_165);
set(h, 'linewidth', 1.5, 'color', line_styles{2}(1), 'linestyle', line_styles{2}(2:end));
h = cdfplot(throughput_170);
set(h, 'linewidth', 1.5, 'color', line_styles{3}(1), 'linestyle', line_styles{3}(2:end));
% Format the axis and legend
title('');
xlabel('Network throughput, packets/sec'); ylabel('CDF');
box on; grid on;
% axis([-Inf Inf 0 1])
leg = legend(legends);
title(leg, 'Source level');
legend('boxoff');