% This script was used to generate random surface waves based on the Pierson-Moskowitz spectrum
% It plots a random wave realization and the PSD such as those whown in Fig. 6 and 7

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

%%% Parameters
L = 1000; % surface length [m]
N = 1000; % DFT points (1 per metre)
resolution = L/N; % spatial grid resolution
Ny_wavelength = 2*resolution; % shortest wavelength that can be resolved, based on Nyquist theorem
fund_freq = 2*pi/L; % fundamental angular spatial frequency [rad/m]
Ny_freq = (N/2)*fund_freq; % Nyquist frequency

rng(12348);

%%% Create a Pierson-Moskowitz variance spectrum function
wind_speed = 10; % wind speed [m/s], only parameter of the Pierson-Moskowitz distribution 
% Create a function handle with angular spatial frequency as the input (only positive values are allowed)
var_spectrum = @(freq) 0.0081 ./ (2.*(freq).^3) .* exp(-0.74 .* ((9.82./freq).^2) ./ (wind_speed^4));

%%% Calculate two-sided discrete random Fourier amplitudes for all frequency sampling points

% Create frequency sampling points for one-sided and two-sided spectra
freq_range_1s = (0:N/2)*fund_freq; % Do calculations using zero-Nyquist frequency range

% Values of the two-sided discrete variance spectrum, based on the one-sided continuous spectrum derived above
var_sp_1s_discrete = fund_freq .* var_spectrum(abs(freq_range_1s));
% Halve the amplitude of the one-sided distribution, except for special cases for zero and Nyquist frequency
var_sp_2s = zeros(size(var_sp_1s_discrete));
var_sp_2s(1) = 0;
var_sp_2s(2:end-1) = var_sp_1s_discrete(2:end-1) ./ 2;
var_sp_2s(end) = var_sp_1s_discrete(end);

% Create a two-sided frequency range and extend two-sided variance spectrum to negative frequencies
freq_range_2s = (-N/2+1:N/2).*fund_freq;
var_sp_2s = [var_sp_2s(end-1:-1:2), var_sp_2s];

% Draw random amplitudes consistent with the variance spectrum
rand_ampl = 1/sqrt(2) .* (randn(size(freq_range_2s)) + 1j.*randn(size(freq_range_2s))) .* sqrt(var_sp_2s);

% Create a different vector of amplitudes that combines the positive and negative frequency points to obtain Hermitian values
herm_ampl = zeros(size(freq_range_2s));
herm_ampl(1:end-1) = 1/sqrt(2) .* (rand_ampl(1:end-1) + conj(fliplr(rand_ampl(1:end-1))));
herm_ampl(end) = rand_ampl(end); % for the Nyquist frequency, simply copy the original random amplitude

% Finally, map the obtained random amplitudes onto the (0:N-1)*Fs frequency range expected by the IFFT function
wave_spectrum = [herm_ampl(N/2:end), herm_ampl(1:N/2-1)];

% The IFFT of this spectrum is the wave elevation in spatial domain
waves = N .* ifft(wave_spectrum, 'symmetric');

%% Plot the wave spectrum and the resulting ocean surface

% Wave one-sided spectrum, power spectral density
figure;
loglog(freq_range_1s, 2.* abs(wave_spectrum(1:N/2+1)).^2 ./ fund_freq, '-', 'linewidth', 1);
hold on;
loglog(freq_range_1s, var_spectrum(freq_range_1s), '--', 'linewidth', 2);
xlabel('Angular spatial frequency, rad/m'); ylabel('PSD, m^2/(rad/m)')
grid on; box on;
axis([-Inf Inf 1e-15 10])
legend('Random realization', 'Variance spectrum', 'Location', 'SouthEast');

% Ocean surface
figure;
plot((0:N-1).*resolution, waves, 'linewidth', 2);
xlabel('Range, m'); ylabel('Height, m')
box on; grid on;
