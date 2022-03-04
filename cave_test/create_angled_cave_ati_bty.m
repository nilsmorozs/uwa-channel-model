function [bty_x, bty_y, topbound_x, topbound_y] = create_angled_cave_ati_bty(pars, cave_height, cave_bend_ranges)
%CREATE_ANFLED_CAVE_BTY_ATI function creates a ATI and BTY files for an
% angled cave simulation

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

% Start with a cave at the top and add bends one after another
topbound_x = 0;
topbound_y = 0; % depth
bty_x = 0;
bty_y = cave_height; % depth
for n = 1:numel(cave_bend_ranges)
    % n is odd: bend downwards
    if mod(n, 2) > 0
        topbound_x = [topbound_x, cave_bend_ranges(n)+cave_height, cave_bend_ranges(n)+cave_height+0.01];
        topbound_y = [topbound_y, 0, pars.maxdepth-cave_height];
        bty_x = [bty_x, cave_bend_ranges(n), cave_bend_ranges(n)+0.01];
        bty_y = [bty_y, cave_height, pars.maxdepth]; % depth
        if n == numel(cave_bend_ranges) % final point at max range
            topbound_x = [topbound_x, pars.maxrange];
            topbound_y = [topbound_y, pars.maxdepth-cave_height];
            bty_x = [bty_x, pars.maxrange];
            bty_y = [bty_y, pars.maxdepth];
        end
    % n is even:bend upwards
    else
        topbound_x = [topbound_x, cave_bend_ranges(n), cave_bend_ranges(n)+0.01];
        topbound_y = [topbound_y, pars.maxdepth-cave_height, 0];
        bty_x = [bty_x, cave_bend_ranges(n)+cave_height, cave_bend_ranges(n)+cave_height+0.01];
        bty_y = [bty_y, pars.maxdepth, cave_height]; % depth
        if n == numel(cave_bend_ranges) % final point at max range
            topbound_x = [topbound_x, pars.maxrange];
            topbound_y = [topbound_y, 0];
            bty_x = [bty_x, pars.maxrange];
            bty_y = [bty_y, cave_height];
        end
    end
end

%%%% Top boundary %%%%%
    
% Create an output ATI file
filename = [pars.filename '.ati'];
% Open a file output stream
fid = fopen(filename, 'w');
% Write first two lines
fprintf(fid, '''L''\n');
fprintf(fid, '%d\n', numel(topbound_x));
% Now write the XY coordinate pairs line by line
for n = 1:numel(topbound_x)
    fprintf(fid, '%f\t%f\n', topbound_x(n)*1e-3, topbound_y(n));
end
% Close the file
fclose(fid);

%%%% Bottom boundary %%%%%

% Create an output ATI file
filename = [pars.filename '.bty'];
% Open a file output stream
fid = fopen(filename, 'w');
% Write first two lines
fprintf(fid, '''L''\n');
fprintf(fid, '%d\n', numel(bty_x));
% Now write the XY coordinate pairs line by line
for n = 1:numel(bty_x)
    fprintf(fid, '%f\t%f\n', bty_x(n)*1e-3, bty_y(n));
end
% Close the file
fclose(fid);
