% This script runs a single BELLHOP simulation and produces a graphical output

% Copyright 2022 Nils Morozs, University of York (nils.morozs@york.ac.uk)
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

%% This part of the script sets up the simulation parameters of a BELLHOP run

% The MATLAB function that creates a BELLHOP ENV file requires a 'pars'
% structure with pre-defined fields, that are populated with default values by the function below
pars = default_sim_pars;

% File name and the simulation title
pars.filename = 'simfiles/single_sim_example'; % do not include '.env' extension, as this name will be used for several file types
pars.title = 'Cave test'; % (this will appear on the plots)

% Specify the simulation type as 'ray' by default, other options are:
%  'ray' - simple ray tracing
%  'eray' - Eigenray tracing 
%  'loss' - 2D propagation loss calculation
%  'arr' - arrivals simulation (outputs attenuation/delay/phase of received echoes)
pars.simtype = 'loss';

% Carrier frequency [Hz]
pars.freq = 24e3;

% Specify source depth [m]
pars.sourcedepths = 50;

% 200m depth, 600m range, flat SSP, hard granite bottom
pars.maxdepth = 300;
pars.maxrange = 700;
pars.depths = 0:pars.maxdepth;
pars.soundspeeds = 1500.0 .* ones(1, numel(pars.depths));
pars.bsp = 4000; % 4000 m/s speed in granite? :)
pars.bdensity = 3.0; % 3x the density of sandsilt? Should be very reflective

% Sinusoidal cave characteristics
cave_bend_ranges = [350];
cave_height = 100;

% Specify receiver depth and range (not used by 'loss' simulation)
pars.rxdepths = 250;
pars.rxranges = pars.maxrange;

% Set random number generator seed for reproducible altimetry/bathymetry
rng(12453);

% Cave altimetry + bathymetry
pars.use_altimetry = true;
pars.use_bathymetry = true;
[bty_x, bty_y, topbound_x, topbound_y] = create_angled_cave_ati_bty(pars, cave_height, cave_bend_ranges);

% Specify the number of rays and the departure angle range [degrees] at the source
if strcmp(pars.simtype, 'ray')
    % Small number of rays for a simple ray trace
    pars.numrays = 21;
    pars.minangle = -15;
    pars.maxangle = 15;
else
    % For the transmission loss, eigenray and arrivals simulations, override the angle range by a full [-90, 90] range
    pars.minangle = -90;
    pars.maxangle = 90;
    % For loss, eigenray and arrivals simulations, simulate more rays than for a simple graphical ray trace
    pars.numrays = 10001;
end

% If 'loss' simulationtyoe is used, enable Thorp absorption and use Gaussian beams
if strcmp(pars.simtype, 'loss')
    pars.thorpabsorb = true;
    pars.gaussianbeams = true;
end

% Create the BELLHOP ENV file using the given paramaters
create_bellhop_env_file(pars);

%% Run BELLHOP using the ENV file that was created
bellhop(pars.filename);

%% Plot the results

% If this was a 'ray' or 'eray' simulation, use the 'plotray' function
if strcmp(pars.simtype, 'ray') || strcmp(pars.simtype, 'eray')
    f = figure;
    f.Renderer = "Painters";
    plotray(pars.filename);
    grid on; box on;
    axis([0 pars.maxrange, 0 pars.maxdepth])
    
% If this was a 'loss' simulation, use the 'plotshd' function
elseif strcmp(pars.simtype, 'loss')
    f = figure; hold on;
    plotshd([pars.filename '.shd']); % this needs to have '.shd' file extension
    c = colorbar('EastOutside');
    c.Label.String = 'Transmission loss, dB';
    c.Label.FontSize = 12;
    plot(0, pars.sourcedepths, 'go', 'linewidth', 2);
    plot(pars.maxrange, pars.rxdepths, 'bs', 'linewidth', 2);
    grid on; box on;
% If this was an 'arr' simulation, process the 'arr' file and plot the impulse response
elseif strcmp(pars.simtype, 'arr')
    
    % Extract impulse response from the output file
    imp_resp = process_arr_file(pars.filename);
    % Normalise the echo amplitudes
    imp_resp{1}.ampl = imp_resp{1}.ampl ./ max(imp_resp{1}.ampl);
    % Calculate compressed versions of the impulse response (Only include echoes that make up 95%/99% of total energy)
    comp_imp_resp_95 = compress_imp_resp(imp_resp{1}, 0.95);
    comp_imp_resp_99 = compress_imp_resp(imp_resp{1}, 0.99);
    
    % Plot the full impulse response and the compressed versions
    figure;

    % Plot delay and apmlitude of all echoes recorded by BELLHOP
    subplot(3, 1, 1);
    stem(imp_resp{1}.delay, imp_resp{1}.ampl, 'r-');
    axis([0.99*min(imp_resp{1}.delay) 1.01*max(imp_resp{1}.delay) 0 Inf])
    xlabel('Delay, sec'); ylabel('Amplitude');
    title('Full BELLHOP impulse response');

    % Include only the echoes that constitute 99% of the total received energy
    subplot(3, 1, 2);
    stem(comp_imp_resp_99.delay, comp_imp_resp_99.ampl, 'b-', 'linewidth', 1);
    axis([0.99*min(imp_resp{1}.delay) 1.01*max(imp_resp{1}.delay) 0 Inf])
    xlabel('Delay, sec'); ylabel('Amplitude');
    title('Compressed impulse response (99% energy)');

    % Include only the echoes that constitute 95% of the total received energy
    subplot(3, 1, 3);
    stem(comp_imp_resp_95.delay, comp_imp_resp_95.ampl, 'b-', 'linewidth', 1);
    axis([0.99*min(imp_resp{1}.delay) 1.01*max(imp_resp{1}.delay) 0 Inf])
    xlabel('Delay, sec'); ylabel('Amplitude');
    title('Compressed impulse response (95% energy)');

    % Plot the full impulse response again and highlight the refracted and reflected paths (plots from the article)
    figure; hold on;
    red_rays = (imp_resp{1}.ntb == 0) & (imp_resp{1}.nbb == 0); % direct paths are red
    green_rays = (imp_resp{1}.ntb > 0) & (imp_resp{1}.nbb == 0); % sea surface reflections are green
    blue_rays = (imp_resp{1}.ntb == 0) & (imp_resp{1}.nbb > 0); % sea bottom reflections are blue
    black_rays = ~red_rays & ~green_rays; % reflections from both surface and bottom are black
    stem(imp_resp{1}.delay(black_rays), imp_resp{1}.ampl(black_rays), 'k-', 'linewidth', 2);
    stem(imp_resp{1}.delay(red_rays), imp_resp{1}.ampl(red_rays), 'r-', 'linewidth', 2);
    stem(imp_resp{1}.delay(green_rays), imp_resp{1}.ampl(green_rays), 'g-', 'linewidth', 2);
    stem(imp_resp{1}.delay(blue_rays), imp_resp{1}.ampl(blue_rays), 'b-', 'linewidth', 2);
    axis([0.99*min(imp_resp{1}.delay) 1.01*max(imp_resp{1}.delay) 0 Inf])
    xlabel('Delay, sec'); ylabel('Amplitude');
    box on; grid on;
    
end

% Unless it is an impulse response plot, plot the surface waves and bathymetry on top
if ~strcmp(pars.simtype, 'arr')
    % Plot surface wave coordinates from the ATI file (2 header lines, tab delimited)
    if pars.use_altimetry
        hold on;
        plotati(pars.filename);
    end
    % Plot bottom coordinates from the BTY file (2 header lines, tab delimited)
    if pars.use_bathymetry
        hold on;
        plotbty(pars.filename);
    end
end