function [ ] = create_sea_surface_file(pars)
%CREATE_SEA_SURFACE_FILE function creates an ATI file for a randomly generated surface wave model
%INPUTS:
% PARS - structure containing parameters needed for the ATI file,
%        (for complete list of the fields run 'help default_sim_pars' in the MATLAB console)
%
%OUTPUT:
% ATI file is created at the same path as the parent ENV file for this simulation

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
    
% Create an output ATI file
filename = [pars.filename '.ati'];

% Use the specified sampling frequency (find the closest even number of DFT points that goes beyond)
resolution  = pars.wave_resolution; % spatial resolution
L = ceil(pars.maxrange); % maximum range [m]
fund_freq = 2*pi/L; % fundamental angular spatial frequency [rad/m]
N = ceil(L/resolution/2) * 2; % number of DFT points (forced to be even)

%%% Create a Pierson-Moskowitz variance spectrum function
% Create a function handle with angular spatial frequency as the input (only positive values are allowed)
var_spectrum = @(freq) 0.0081 ./ (2.*(freq).^3) .* exp(-0.74 .* ((9.82./freq).^2) ./ (pars.wind_speed^4));

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
waves = abs(waves - max(waves)); % make sure they are all below zero (for BELLHOP compatibility)

% Open a file output stream
fid = fopen(filename, 'w');

% Write first two lines
fprintf(fid, '''L''\n');
fprintf(fid, '%d\n', N);

% Now write the XY coordinate pairs line by line
for n = 1:N
    fprintf(fid, '%f\t%f\n', (n-1)*resolution*1e-3, waves(n));
end

% Close the file
fclose(fid);
