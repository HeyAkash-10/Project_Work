function ordered_vertices = orderVerticesUsingAdjMatrix(edges)
% edges: array of structs with fields v1 and v2, each 1x3 vector
% ordered_vertices: Nx3 array of ordered vertices

    % Step 1: Collect all unique vertices
    vertex_list = [];
    for i = 1:length(edges)
        vertex_list = [vertex_list; edges(i).v1; edges(i).v2];
    end
    % Remove duplicates
    [unique_vertices, ~, ic] = unique(round(vertex_list, 8), 'rows');

    n = size(unique_vertices, 1); % number of unique vertices

    % Step 2: Build adjacency matrix
    A = zeros(n, n); % adjacency matrix

    for i = 1:length(edges)
        idx1 = find(ismember(unique_vertices, round(edges(i).v1, 8), 'rows'));
        idx2 = find(ismember(unique_vertices, round(edges(i).v2, 8), 'rows'));
        A(idx1, idx2) = 1;
        A(idx2, idx1) = 1; % undirected
    end

    % Step 3: Find endpoint (vertex with degree 1)
    deg = sum(A, 2);
    start_idx = find(deg == 1, 1); % open path
    if isempty(start_idx)
        start_idx = 1; % closed loop, start anywhere
    end

    % Step 4: Traverse path
    visited = false(n, 1);
    ordered_indices = zeros(n, 1);
    ordered_indices(1) = start_idx;
    visited(start_idx) = true;

    for i = 2:n
        neighbors = find(A(ordered_indices(i-1), :) & ~visited');
        if isempty(neighbors)
            break;
        end
        ordered_indices(i) = neighbors(1);
        visited(neighbors(1)) = true;
    end

    % Step 5: Return ordered vertices
    ordered_vertices = unique_vertices(ordered_indices(ordered_indices > 0), :);

% Test INPUT:
% edges(1).v1 = [0 0 0]; edges(1).v2 = [10 0 0];
% edges(2).v1 = [10 0 0]; edges(2).v2 = [10 10 0];
% edges(3).v1 = [10 10 0]; edges(3).v2 = [0 10 0];
% 
% ordered = orderVerticeUsingAdjMatrix(edges);
% 
% disp('Ordered vertices:');
% disp(ordered);

end


