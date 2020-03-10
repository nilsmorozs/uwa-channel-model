% Plot the January and July SSP (Fig. X)

% Load and store the SSP data from both files
max_depth = 70; % maximum depth
load('data/north_sea_ssp_jan.mat');
depths_jan = z;
speeds_jan = c;
load('data/north_sea_ssp_jul.mat');
depths_jul = z;
speeds_jul = c;

% Plot both SSPs
figure; hold on
plot(speeds_jan, -depths_jan, 'b-', 'Linewidth', 1.5)
plot(speeds_jul, -depths_jul, 'r-.', 'Linewidth', 1.5)
xlabel('Sound speed, m/s')
yticks(-max_depth:10:0);
yticklabels(max_depth:-10:0);
ylabel('Depth, m');
title('');
legend('January', 'July', 'Location', 'SouthEast')
legend('boxoff')
box on;
axis([1476 1504 -max_depth 0])