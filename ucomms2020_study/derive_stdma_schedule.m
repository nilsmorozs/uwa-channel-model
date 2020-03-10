function [stdma_sched, slot_length] = derive_stdma_schedule(intf_map, prop_delays, delay_spreads, Td)
%DERIVE_STDMA_SCHEDULE function derives an STDMA schedule tailored to the linear network
% scenario simulated in this paper, where every node is a data source (except the #1 sink node)
%
%INPUTS:
% INTF_MAP - binary [NxN] indicating which nodes interfere with which other nodes
% PROP_DELAYS - [NxN] matrix of propagation delays
% DELAY_SPREADS - [NxN] matrix of channel delay spreads
% TD - data packet duration [s]
%
%OUTPUTS:
% TDMA_SCHED - Matrix indicating the time slots used by every node in the TDMA schedule
% SLOT_LENGTH - minimum duration of the TDMA slot [s]

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

% Create a matrix of logical zeros where we will indicate slot indices used by every node in the STDMA schedule
num_nodes = size(intf_map, 1);
stdma_sched = false(num_nodes, num_nodes*(num_nodes-1)/2); % the number of columns is the total number of transmissions

% Keep looping through the slots until the full schedule is completed, i.e. when node 2 transmits the final packet to sink node
t = 1;
while (sum(stdma_sched(2, :)) < num_nodes-1)
    
    % Loop through every node except sink, and check if its transmission can be scheduled in current slot
    for n = 2:num_nodes
        
        % Calculate the number of transmissions already scheduled for this and previous node (n+1)
        num_tx = sum(stdma_sched(n, :));
        if n == num_nodes
            num_tx_prev_node = 0; % there is no previous node, set to zero
        else
            num_tx_prev_node = sum(stdma_sched(n+1, :));
        end
        
        % Assign this slot to this node if it meets the following criteria:
        %   - it has not already transmitted all of its packets
        %   - the previous node has transmitted enough packets to forward 
        %   - it will not interfere with nodes that were already assigned this slot
        if (num_tx < num_nodes-n+1) && (num_tx_prev_node >= num_tx) ...  
           && ~any( stdma_sched(:, t)' & (intf_map(n, :) | intf_map(:, n)') )
            % Mark this time slot as used by this node
            stdma_sched(n, t) = true;
        end
        
    end
    
    % Increment the time slot
    t = t + 1;
end

% Remove all extra zero columns at the end of the schedule
stdma_sched = stdma_sched(:, any(stdma_sched));

% The TDMA slot length is equal to the maximum propagation delay + delay spread of an active link + Td + Tg
tx_on_links = true(num_nodes);
tx_on_links(1, :) = false; % the sink node never transmits
max_delay = max(prop_delays(intf_map & tx_on_links) + delay_spreads(intf_map & tx_on_links));
slot_length = Td + max_delay;

end

