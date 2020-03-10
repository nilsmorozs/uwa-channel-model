% Plot the January and July SSP (Fig. X)

% Load and store the SSP data from both files
max_depth = 50; % maximum depth
load('data/north_sea_ssp_jan.mat');
depths_jan = z(z <= max_depth);
speeds_jan = c(z <= max_depth);
load('data/north_sea_ssp_jul.mat');
depths_jul = z(z <= max_depth);
speeds_jul = c(z <= max_depth);

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
axis([-Inf Inf -max_depth 0])