function [ch_gain, ch_delay, delay_spread, reverb_ch_gain] = process_imp_resp(imp_resp, centre_freq, bandwidth, mean_sp, coherent_multipath, signal_vs_reverb_time)
%PROCESS_IMP_RESP returns the overall gain, delay and delay spread of a wideband channel described by its impulse response
%
%INPUTS:
% IMP_RESP - structure containing amplitude, phases and delays of the echoes making up the channel
% CENTRE_FREQ - centre frequency [Hz]
% BANDWIDTH - bandwidth [Hz]
% MEAN_SP - mean sound speed [m/s], needed for calculating the absorption loss
% COHERENT_MULTIPATH - flag indicating whether echoes should be added coherently or ignoring the phase
% SIGNAL_VS_REVERB_TIME - length of time window (from first received path)
%                         during which useful signal is received (any paths arriving afterwards is reverb)
%
%OUTPUTS:
% CH_GAIN - channel gain [dB]
% CH_DELAY - propagation delay [s]
% DELAY_SPREAD - delay spread, i.e. difference between first and last echo arrival [s]

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

% Default input values
if nargin < 5
    coherent_multipath = true;
end
if nargin < 6
    signal_vs_reverb_time = Inf; % no reverb, for back compatibility [this is a new feature]
end

% If there are no echoes, return a channel with infinitely high loss
if imp_resp.num_echoes < 1
    ch_gain = -Inf;
    ch_delay = 0;
    delay_spread = 0;
    reverb_ch_gain = -Inf;
    return;
end

% Create a vector of frequency sampling points used for integrating receiver power across a specified bandwidth
step_size = 1; % 1 Hz step size (needs to be small enough to capture all frequency selective fading)
freq_points = linspace(centre_freq-bandwidth/2, centre_freq+bandwidth/2, ceil(bandwidth/step_size)+1)';
freq_points_kHz = freq_points .* 1e-3;

% Estimate distance every echo has travelled for calculating the absorption loss
% This might have slight inacurracy due to variable propagation speed, but it will have a
% negligible effect on the overall results
dist = mean_sp .* imp_resp.delay .* 1e-3; % [km]

% Calculate phase and absorption coefficient for every echo at every frequency sampling point
phases = NaN(numel(freq_points), imp_resp.num_echoes);
abs_loss = NaN(numel(freq_points), imp_resp.num_echoes);
for echo = 1:imp_resp.num_echoes
    % Determine signal phase using the delay and the additional phase shift produced by BELLHOP
    phases(:, echo) = -2.*pi .* freq_points .*  imp_resp.delay(echo) + imp_resp.phase_shift(echo);
    % Use Thorp empirical formula for absoption loss
    abs_coeff_dB = 0.11 .* (freq_points_kHz.^2 ./ (1 + freq_points_kHz.^2)) ...
        + 44 .* (freq_points_kHz.^2 ./ (4100 + freq_points_kHz.^2)) ...
        + 3e-4 .* freq_points_kHz.^2 + 3.3e-3;
    abs_loss(:, echo) = 10.^( abs_coeff_dB ./10 ) .^ dist(echo);
end

% Indices of echoes contributing to the useful signal
sig = imp_resp.delay <= (min(imp_resp.delay) + signal_vs_reverb_time);

% Calculate the complex channel coefficient at every frequency sampling
% point (for both signal and reverb parts)
if coherent_multipath
   
    % If multipath is added coherently, use full amplitude and phase information to add echoes
    rx_echoes = repmat(imp_resp.ampl(sig), numel(freq_points), 1) .* exp(1j.*phases(sig)) ./ sqrt(abs_loss(sig));
    ch_coeff = sum(rx_echoes, 2);
    reverb_echoes = repmat(imp_resp.ampl(~sig), numel(freq_points), 1) .* exp(1j.*phases(~sig)) ./ sqrt(abs_loss(~sig));
    reverb_ch_coeff = sum(reverb_echoes, 2);
else
    % Otherwise, add echoes using the power law, discarding the phase information
    rx_echo_powers = repmat(abs(imp_resp.ampl(sig)).^2, numel(freq_points), 1) ./ abs_loss(sig);
    ch_coeff = sqrt(sum(rx_echo_powers, 2));
    reverb_echo_powers = repmat(abs(imp_resp.ampl(~sig)).^2, numel(freq_points), 1) ./ abs_loss(~sig);
    reverb_ch_coeff = sqrt(sum(reverb_echo_powers, 2));
end

% Calculate the linear power gain by integrating across the bandwidth
lin_gain = trapz(freq_points, abs(ch_coeff).^2) / bandwidth;
if any(~sig)
    reverb_lin_gain = trapz(freq_points, abs(reverb_ch_coeff).^2) / bandwidth;
else
    reverb_lin_gain = 0;
end

% Return the channel gain in dB, delay of the first echo arrival, and delay spread
ch_gain = 10*log10(lin_gain);
reverb_ch_gain = 10*log10(reverb_lin_gain);
ch_delay = min(imp_resp.delay);
delay_spread = max(imp_resp.delay) - min(imp_resp.delay);