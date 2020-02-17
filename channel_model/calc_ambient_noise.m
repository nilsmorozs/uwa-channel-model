function noise_power = calc_ambient_noise(centre_freq, bandwidth, ship_act, wind_speed)
%CALC_AMBIENT_NOISE function returns the noise power in dB re 1 uPa @ 1m,
% calculated using the ambient noise model from 4 sources: shipping, wind, turbulence and thermal
%
%INPUTS:
% CENTRE_FREQ - centre frequency [Hz]
% BANDWIDTH - bandwidth [Hz]
% SHIP_ACT - shipping activity factor [0(none), 1(high)]
% WIND_SPEED - wind speed [m/s], used to calculate the wave noise
%
%OUTPUTS:
% NOISE_POWER - total wideband noise power [dB re 1 uPa @ 1m]

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

% Create 1000 sampling points for numeric integration
freq_points = linspace(centre_freq-bandwidth/2, centre_freq+bandwidth/2, 1000)';
freq_points_kHz = freq_points .* 1e-3;

% Calculate noise from 4 different sources: shipping, wind, turbulence and thermal
noise_turb = 17 - 30.*log10(freq_points_kHz);
noise_ship = 40 + 20*(ship_act-0.5) + 26.*log10(freq_points_kHz) - 60.*log10(freq_points_kHz + 0.03);
noise_waves = 50 + 7.5*sqrt(wind_speed) + 20.*log10(freq_points_kHz) - 40.*log10(freq_points_kHz + 0.4);
noise_therm = -15 + 20.*log10(freq_points_kHz);
total_noise = 10.^(noise_turb./10) + 10.^(noise_ship./10) + 10.^(noise_waves./10) + 10.^(noise_therm./10);

% Integrate across all frequency points to obtain noise power
% Here we do not normalize the integration result by the bandwidth, because the underlying data is in dB/Hz
noise_power = 10*log10(trapz(freq_points, total_noise)); % dB re 1 uPa @ 1m