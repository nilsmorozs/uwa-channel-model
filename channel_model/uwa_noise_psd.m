% This script plots PSD for different types of underwater noise (Fig. 14 in the paper)

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

%% Calculate noise values

% Initialise frequency range for plotting
freq_range = 10.^(0:0.1:6); % Hz

% Set shipping activity factor and wind speed
ship_act = 0.5;
wind_speed = 10; % m/s

% Calculate power spectral density of different noise sources [dB/Hz re 1uPa]
noise_turb = 17 - 30.*log10(freq_range.*1e-3);
noise_ship = 40 + 20*(ship_act-0.5) + 26.*log10(freq_range.*1e-3) - 60.*log10(freq_range.*1e-3 + 0.03);
noise_waves = 50 + 7.5*sqrt(wind_speed) + 20.*log10(freq_range.*1e-3) - 40.*log10(freq_range.*1e-3 + 0.4);
noise_therm = -15 + 20.*log10(freq_range.*1e-3);

% Calculate total noise power spectral density
total_noise = 10.*log10( 10.^(noise_turb./10) + 10.^(noise_ship./10) + 10.^(noise_waves./10) + 10.^(noise_therm./10) );

%% Plot the noise PSD

% Specify legends and line styles
line_styles = {'c--', 'g-.', 'b-.', 'r:', 'k-'};
legends = {'Turbulence', 'Shipping', 'Waves', 'Thermal', 'Total Noise PSD'};

% Plot different types of noise separately, and all together
figure;
semilogx(freq_range, noise_turb, line_styles{1}, 'linewidth', 1.5);
hold on;
semilogx(freq_range, noise_ship, line_styles{2}, 'linewidth', 1.5);
semilogx(freq_range, noise_waves, line_styles{3}, 'linewidth', 1.5);
semilogx(freq_range, noise_therm, line_styles{4}, 'linewidth', 1.5);
semilogx(freq_range, total_noise, line_styles{5}, 'linewidth', 1.5);
legend(legends, 'Location', 'NorthEast');
legend('boxoff');
box on; grid on;
xlabel('Frequency, Hz');
ylabel('Noise PSD, dB/Hz re 1{\mu}Pa @ 1m');
axis([0 Inf 10 110]);