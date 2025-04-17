function [connectivity_list, connectivity, unique_connections, adjacency_matrix] = buildConnectivityLists(all_points, all_labels)
% BUILDCONNECTIVITYLISTS Creates connectivity lists for a mesh of points
%   [connectivity_list, connectivity, unique_connections, adjacency_matrix] = buildConnectivityLists(all_points, all_labels)
%
%   Inputs:
%       all_points - Nx2 matrix of point coordinates (x,y)
%       all_labels - Nx1 vector of point labels
%
%   Outputs:
%       connectivity_list - Cell array containing connectivity strings
%       connectivity - Matrix of node connections [node1, node2]
%       unique_connections - Matrix of unique node connections
%       adjacency_matrix - Adjacency matrix representing node connections

% Create a mapping of all nodes to their labels
node_map = containers.Map('KeyType', 'double', 'ValueType', 'double');
for i = 1:size(all_points, 1)
    node_map(i) = all_labels(i);
end
 
% Process Delaunay triangulation for node connectivity
dt = delaunayTriangulation(all_points(:,1), all_points(:,2));
mesh_edges = edges(dt);

% Initialize an adjacency matrix for node connectivity
num_all_nodes = max(all_labels);
adjacency_matrix = zeros(num_all_nodes, num_all_nodes);

% Add connections from mesh edges
for i = 1:size(mesh_edges, 1)
    node1 = all_labels(mesh_edges(i, 1));
    node2 = all_labels(mesh_edges(i, 2));
    adjacency_matrix(node1, node2) = 1;
    adjacency_matrix(node2, node1) = 1;
end

% Create connectivity strings in the requested format
connectivity_list = cell(size(all_points, 1), 1);
for i = 1:size(all_points, 1)
    current_node = all_labels(i);
    connections = find(adjacency_matrix(current_node, :) == 1);
    
    if ~isempty(connections)
        connectivity_list{i} = [num2str(current_node)];
        for j = 1:length(connections)
            connectivity_list{i} = [connectivity_list{i}, '-', num2str(connections(j))];
        end
    else
        connectivity_list{i} = num2str(current_node); % Node with no connections
    end
end

% Store unique node connections for reference
unique_connections = [];
for i = 1:num_all_nodes
    for j = i+1:num_all_nodes
        if adjacency_matrix(i,j) == 1
            unique_connections = [unique_connections; i, j];
        end
    end
end

% Create the connectivity matrix as requested
% Format: [node1, node2] where node1, node2 are the labels of connected nodes
connectivity = [];  % Initialize empty array instead of preallocating

% Only add connections that directly come from the Delaunay triangulation
for i = 1:size(mesh_edges, 1)
    node1 = all_labels(mesh_edges(i, 1));
    node2 = all_labels(mesh_edges(i, 2));
    
    % Ensure the smaller label is first (consistent ordering)
    if node1 > node2
        temp = node1;
        node1 = node2;
        node2 = temp;
    end
    
    % Add the connection if it's not already in the list
    if isempty(connectivity) || ~any(all(connectivity == [node1, node2], 2))
        connectivity = [connectivity; node1, node2];
    end
end

% Sort by first column, then by second column for clarity
connectivity = sortrows(connectivity);
end