% This script was used in Subsection 5C to create a statistical channel model for a pair of nodes
% obtained via BELLHOP simulations with small-scale variation in node positions

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

% Set random seed for reproducibility
rng(12357);

% Choose the name of the output CSV file for storing the channel data
csv_file = 'data/stat_channel_data_surf2bed.csv';
gen_new_data = false; % if data already exists, set to 'false' to load the data for plotting
% Set to 'true' to run BELLHOP and generate new data (will take a few minutes)

%% Run BELLHOP simulations and save results in a CSV file

if gen_new_data
    % Choose the average positions of the source and receiver and the radius of the sphere of their movement
    avg_src_pos = [0, 0, 20]; % source at 480m depth (near bottom)
    avg_rx_pos = [4e3, 0, 480]; % receiver 4km away at 480m depth (near bottom)
    movement_rad = 10; % random node movement within a 10m sphere

    % Generate 50 positions for both source and receiver with random displacements
    num_rand_pos = 50;
    rand_rad = movement_rad.*rand([num_rand_pos, 2]); % random uniform radius 
    rand_azim = 2.*pi.*rand([num_rand_pos, 2]); % random azimuth between 0 and 2*pi
    rand_elev = pi.*(rand([num_rand_pos, 2])-0.5); % random elevation between -pi/2 and pi/2
    [x, y, z] = sph2cart(rand_azim(:, 1), rand_elev(:, 1), rand_rad(:, 1)); % transform to Cartesian
    src_pos = repmat(avg_src_pos, [num_rand_pos, 1]) + [x, y, z];
    [x, y, z] = sph2cart(rand_azim(:, 2), rand_elev(:, 2), rand_rad(:, 2)); % transform to Cartesian
    rx_pos = repmat(avg_rx_pos, [num_rand_pos, 1]) + [x, y, z];

    % Run BELLHOP and generate the new data
    create_3d_channel_lut(src_pos, rx_pos, csv_file);
end

%% Analyze the channel gains, delays and delay spreads

% Read the data from the generated CSV file
csv_data = csvread(csv_file, 1, 2);
ch_gains = csv_data(:, 1);
ch_delays = csv_data(:, 2);
delay_spreads = csv_data(:, 3);

% Plot the CDFs of all three variables separately
plot_cdfs = true; % plot CDFs at all?
plot_in_same_window = true; % three plots in one window?
line_colour = 'b';
line_style = '-';
if plot_cdfs
    if plot_in_same_window
        figure;
    end
    % Channel gain
    if plot_in_same_window; subplot(1, 3, 1); else; figure; end
    h = cdfplot(ch_gains);
    set(h, 'linewidth', 1.5, 'color', line_colour, 'linestyle', line_style);
    xlabel('Channel gain, dB'), ylabel('CDF');
    title('')
    box on; grid off;
    % Channel delay
    if plot_in_same_window; subplot(1, 3, 2); else; figure; end
    h = cdfplot(ch_delays);
    set(h, 'linewidth', 1.5, 'color', line_colour, 'linestyle', line_style);
    xlabel('Channel delay, sec'), ylabel('CDF');
    title('')
    box on; grid off;
    % Delay spread
    if plot_in_same_window; subplot(1, 3, 3); else; figure; end
    h = cdfplot(delay_spreads);
    set(h, 'linewidth', 1.5, 'color', line_colour, 'linestyle', line_style);
    xlabel('Delay spread, sec'), ylabel('CDF');
    title('')
    box on; grid off;
end

% Manually fit a PDF to the linear channel gain data
lin_ch_gains = 10.^(ch_gains./10); % convert from dB to linear
fit_pdf_to_lin_data = true;
if fit_pdf_to_lin_data
    pdf_sample_points = linspace(0, 1e-8, 500);
    if strcmp(csv_file(end-11:end-4), 'surf2bed')
        mu = -20.15; sigma = 0.41; %% Surface to sea bed case
    elseif strcmp(csv_file(end-10:end-4), 'mid2mid')
        mu = -20.5; sigma = 0.38; %% Mid-column to mid-column case
    elseif strcmp(csv_file(end-10:end-4), 'bed2bed')
        mu = -21.1; sigma = 0.6; %% Sea bed to sea bed case
    end
    
    pdf_fit_lin = pdf('Lognormal', pdf_sample_points, mu, sigma);
end

% Plot the histogram of the linear channel gain
figure; hold on;
histogram(lin_ch_gains, 30, 'Normalization', 'pdf');
xlabel('Channel gain, linear')
ylabel('Probability density function')
if fit_pdf_to_lin_data
    plot(pdf_sample_points, pdf_fit_lin, 'r--', 'linewidth', 2)
    legend('BELLHOP data', ['Lognormal PDF:\mu=' num2str(mu, '%.1f') ',\sigma=' num2str(sigma)], 'Location', 'NorthEast');
    legend('boxoff')
end
axis([0 0.6e-8 0 Inf]);
box on; grid off;