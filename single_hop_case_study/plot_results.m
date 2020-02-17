% This script plots the results of the Riverbed Modeler case study
% of the single-hop ALOHA underwater acoustic sensor network

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

% Load the results
load('results.mat');

% Plot throughput vs offered traffic
figure; hold on;
plot(ot.*100, tput_basic.*100, 'r--o', 'linewidth', 1.5);
plot(ot.*100, tput_urick.*100, 'b-.^', 'linewidth', 1.5);
plot(ot.*100, tput_bh.*100, 'k-*', 'linewidth', 1.5);
grid on; box on;
% Format the legend
legend('Binary collision model', 'Urick propagation model', 'BELLHOP channel model', 'Location', 'SouthEast');
legend('boxoff');
% Format the axis
xlabel('Offered traffic, % of capacity');
ylabel('Network throughput, % of capacity');

% Plot packet loss distribution for three channel models
figure; hold on;
h = cdfplot(1 - pkt_stats_basic(:, 2)./pkt_stats_basic(:, 1));
set(h, 'linewidth', 1.5, 'color', 'r', 'linestyle', '--');
h = cdfplot(1 - pkt_stats_urick(:, 2)./pkt_stats_urick(:, 1));
set(h, 'linewidth', 1.5, 'color', 'b', 'linestyle', '-.');
h = cdfplot(1 - pkt_stats_bh(:, 2)./pkt_stats_bh(:, 1));
set(h, 'linewidth', 1.5, 'color', 'k', 'linestyle', '-');
grid on; box on;
% Format the legend
legend('Binary collision model', 'Urick propagation model', 'BELLHOP channel model', 'Location', 'SouthEast');
legend('boxoff');
% Format the axis
xlabel('Packet loss per node');
ylabel('CDF');
title('')