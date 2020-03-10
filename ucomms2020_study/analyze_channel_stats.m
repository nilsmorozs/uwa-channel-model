% Script that plots the channel statistics for the sme link in June and January


% Read the data from the speficied CSV file
csv_file = 'data/ch_data-jul-2hop.csv';
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
    xlabel('X, dB'), ylabel('P(channel gain \leq X)');
    if plot_in_same_window
        title('CDF of the channel gain'); 
    else
        title('')
    end
    box on; grid off;
    % Channel delay
    if plot_in_same_window; subplot(1, 3, 2); else; figure; end
    h = cdfplot(ch_delays);
    set(h, 'linewidth', 1.5, 'color', line_colour, 'linestyle', line_style);
    xlabel('t, s'), ylabel('P(channel delay \leq t)');
    if plot_in_same_window
        title('CDF of the channel delay'); 
    else
        title('')
    end
    box on; grid off;
    % Delay spread
    if plot_in_same_window; subplot(1, 3, 3); else; figure; end
    h = cdfplot(delay_spreads);
    set(h, 'linewidth', 1.5, 'color', line_colour, 'linestyle', line_style);
    xlabel('\tau, s'), ylabel('P(delay spread \leq \tau)');
    if plot_in_same_window
        title('CDF of the delay spread'); 
    else
        title('')
    end
    box on; grid off;
end

% Manually fit a PDF to the linear channel gain data
lin_ch_gains = 10.^(ch_gains./10); % convert from dB to linear
fit_pdf_to_lin_data = false;
if fit_pdf_to_lin_data
    pdf_sample_points = linspace(0, 1e-8, 500);
    if strcmp(csv_file(end-11:end-4), 'surf2bed')
        mu = -19.8; sigma = 0.5; %% Surface to sea bed case
    elseif strcmp(csv_file(end-10:end-4), 'mid2mid')
        mu = -20.3; sigma = 0.45; %% Mid-column to mid-column case
    elseif strcmp(csv_file(end-10:end-4), 'bed2bed')
        mu = -20.8; sigma = 0.9; %% Sea bed to sea bed case
    end
    
    pdf_fit_lin = pdf('Lognormal', pdf_sample_points, mu, sigma);
end

% Plot the histogram of the linear channel gain
figure; hold on;
histogram(lin_ch_gains, 'Normalization', 'pdf');
xlabel('Channel gain, linear')
ylabel('Probability density function')
if fit_pdf_to_lin_data
    plot(pdf_sample_points, pdf_fit_lin, 'r--', 'linewidth', 2)
    legend('BELLHOP data', ['Lognormal PDF:\mu=' num2str(mu, '%.1f') ',\sigma=' num2str(sigma)], 'Location', 'NorthEast');
    legend('boxoff')
end
box on; grid off;