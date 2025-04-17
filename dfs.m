function orderedPolygon = orderPolygonVertices(vertices)
    % Order polygon vertices using DFS
    % Input: unordered vertices as an n x 2 matrix
    % Output: ordered vertices ready for plotting
    
    % Calculate adjacency matrix based on distances
    n = size(vertices, 1);
    adjMatrix = zeros(n, n);
    
    % Compute distances between all pairs of points
    distMatrix = zeros(n, n);
    for i = 1:n
        for j = 1:n
            distMatrix(i,j) = norm(vertices(i,:) - vertices(j,:));
        end
    end
    
    % For each vertex, connect it to its two closest neighbors
    for i = 1:n
        % Sort distances and get indices of two closest points (excluding self)
        [~, sortedIndices] = sort(distMatrix(i,:));
        twoClosest = sortedIndices(2:3); % Skip first (self)
        
        % Create edges to the two closest points
        adjMatrix(i, twoClosest) = 1;
        adjMatrix(twoClosest, i) = 1;
    end
    
    % Remove potential diagonal connections for polygons
    refineAdjMatrix(adjMatrix, vertices);
    
    % Perform DFS to get ordered vertices
    visited = false(1, n);
    orderedIndices = [];
    
    % Start DFS from first vertex
    dfs(1);
    
    % Add the first vertex again to close the polygon
    orderedIndices = [orderedIndices, orderedIndices(1)];
    
    % Get ordered vertices
    orderedPolygon = vertices(orderedIndices, :);
    
    % Display results
    visualizeResults(vertices, orderedPolygon, adjMatrix);
    
    function dfs(vertex)
        visited(vertex) = true;
        orderedIndices = [orderedIndices, vertex];
        
        % Find all adjacent vertices
        neighbors = find(adjMatrix(vertex, :));
        
        % Visit unvisited neighbors
        for i = 1:length(neighbors)
            neighbor = neighbors(i);
            if ~visited(neighbor)
                dfs(neighbor);
            end
        end
    end
end

function refineAdjMatrix(adjMatrix, vertices)
    % Remove diagonal connections when they don't belong to the polygon perimeter
    n = size(vertices, 1);
    
    % This function would be more sophisticated for generalized polygons
    % For now, we'll keep the adjacency matrix as is
end

function visualizeResults(originalVertices, orderedVertices, adjMatrix)
    % Plot original and ordered vertices
    figure;
    
    % Plot original vertices
    subplot(1, 2, 1);
    scatter(originalVertices(:,1), originalVertices(:,2), 100, 'filled');
    hold on;
    
    % Draw edges according to adjacency matrix
    n = size(originalVertices, 1);
    for i = 1:n
        for j = i+1:n
            if adjMatrix(i, j) > 0
                line([originalVertices(i,1), originalVertices(j,1)], ...
                     [originalVertices(i,2), originalVertices(j,2)], ...
                     'Color', 'b', 'LineWidth', 1.5);
            end
        end
    end
    
    % Label vertices
    for i = 1:n
        text(originalVertices(i,1)+0.1, originalVertices(i,2)+0.1, ...
             num2str(i), 'FontSize', 12);
    end
    title('Original Vertices with Adjacency Connections');
    axis equal;
    
    % Plot ordered vertices
    subplot(1, 2, 2);
    scatter(orderedVertices(:,1), orderedVertices(:,2), 100, 'filled');
    hold on;
    
    % Connect ordered vertices
    line(orderedVertices(:,1), orderedVertices(:,2), 'Color', 'r', 'LineWidth', 2);
    
    % Label vertices
    for i = 1:size(orderedVertices, 1)-1
        text(orderedVertices(i,1)+0.1, orderedVertices(i,2)+0.1, ...
             num2str(i), 'FontSize', 12);
    end
    
    title('Ordered Polygon');
    axis equal;
end

% Extended version to handle arbitrary polygons with auto-rotation
function orderedPolygon = orderAndOrientPolygon(vertices)
    % First order the vertices
    orderedPolygon = orderPolygonVertices(vertices);
    
    % Remove the last vertex (which is a duplicate of the first)
    orderedPolygon = orderedPolygon(1:end-1, :);
    
    % Find the centroid
    centroid = mean(orderedPolygon, 1);
    
    % Compute the angles of each vertex with respect to the centroid
    angles = atan2(orderedPolygon(:,2) - centroid(2), ...
                  orderedPolygon(:,1) - centroid(1));
    
    % Find the vertex with the minimum angle (closest to "east")
    [~, minIndex] = min(angles);
    
    % Reorder vertices to start from the minimum angle
    n = size(orderedPolygon, 1);
    reorderedIndices = mod(minIndex:minIndex+n-1, n);
    reorderedIndices(reorderedIndices == 0) = n;
    
    orderedPolygon = orderedPolygon(reorderedIndices, :);
    
    % Add the first vertex again to close the polygon
    orderedPolygon = [orderedPolygon; orderedPolygon(1,:)];
    
    % Plot the result
    figure;
    plot(orderedPolygon(:,1), orderedPolygon(:,2), 'r-o', 'LineWidth', 2);
    hold on;
    plot(centroid(1), centroid(2), 'k*', 'MarkerSize', 10);
    
    % Label vertices
    for i = 1:n
        text(orderedPolygon(i,1)+0.1, orderedPolygon(i,2)+0.1, ...
             num2str(i), 'FontSize', 12);
    end
    
    title('Auto-Oriented Polygon');
    axis equal;
end

% Example usage:
% 1. For a square:
% vertices = [0,0; 1,0; 0,1; 1,1]; % Unordered square vertices
% orderedSquare = orderPolygonVertices(vertices);

% 2. For arbitrary polygon with auto-orientation:
vertices = rand(6,2)*10; % Random polygon with 6 vertices
orderedPolygon = orderAndOrientPolygon(vertices);


% 3. For a triangle:
% vertices = [0,0; 2,0; 1,2]; % Unordered triangle vertices 
% orderedTriangle = orderPolygonVertices(vertices);