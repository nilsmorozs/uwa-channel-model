function noise_power = calc_ambient_noise(centre_freq, bandwidth, ship_act, wind_speed)
%CALC_AMBIENT_NOISE function returns the noise power as linear factor relative to 1 uPa @ 1m,
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

% Author: Nils Morozs
% Department of Electronic Engineering, University of York, 2018

% Create many sampling points for numeric integration
freq_points = (centre_freq-bandwidth/2 : bandwidth/1000 : centre_freq+bandwidth/2)';
freq_points_kHz = freq_points .* 1e-3;

% Calculate noise from 4 different sources: shipping, wind, turbulence and thermal
noise_turb = 17 - 30.*log10(freq_points_kHz);
noise_ship = 40 + 20*(ship_act-0.5) + 26.*log10(freq_points_kHz) - 60.*log10(freq_points_kHz + 0.03);
noise_waves = 50 + 7.5*sqrt(wind_speed) + 20.*log10(freq_points_kHz) - 40.*log10(freq_points_kHz + 0.4);
noise_therm = -15 + 20.*log10(freq_points_kHz);
total_noise = 10.^(noise_turb./10) + 10.^(noise_ship./10) + 10.^(noise_waves./10) + 10.^(noise_therm./10);

% Integrate across all frequency points to obtain noise power
% Here we do not normalize the inegration result by the bandwidth, because the underlying data is in dB/Hz
noise_power = 10*log10(trapz(freq_points, total_noise)); % dB re 1 uPa @ 1m