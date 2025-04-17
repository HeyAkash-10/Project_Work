clc; clear; close all;


%% Step 1: Load Data
theta = input('Enter the angle (in degrees) from the vertical: ');
theta_rad = deg2rad(theta); 
bridge_length = input('Enter the bridge length in mm: ');
stlFile='cuboid.stl';
[edges_on_slice, convexHulls,no_of_slices]=sliceSTL(stlFile, bridge_length);
numSlices = no_of_slices;

ordered = orderVerticeUsingAdjMatrix(edges_on_slice);

disp('Ordered vertices:');
disp(ordered);

%% Step 2: Extract edges from the current slice
% Process each slice
for slice_idx = 1:numSlices
    % slice_idx = 1;
    % Extract edges from the current slice
    edges_data = edges_on_slice(slice_idx);   
    x_shape = [ordered(:,2);ordered(1,2)];  
    y_shape = [ordered(:,3);ordered(1,3)];
    figure;
    axis equal; grid on;
    hold on;
    plot(x_shape, y_shape, 'b-', 'LineWidth', 2);
    scatter(x_shape, y_shape, 50, 'r', 'filled');
    xlabel('Y'); ylabel('Z');
    title(['Slice ', num2str(slice_idx)]);

    %% Step 3: Find and Extend Bounding Box
    min_x = min(x_shape);
    max_x = max(x_shape);
    min_y = min(y_shape);
    max_y = max(y_shape);

    box_width = max_x - min_x;
    min_x_extended = min_x - box_width;
    max_x_extended = max_x + box_width;

    rectangle('Position', [min_x_extended, min_y, max_x_extended - min_x_extended, max_y - min_y], 'EdgeColor', 'k', 'LineWidth', 2);
    disp(['Extended Bounding Box: Min X = ', num2str(min_x_extended), ', Max X = ', num2str(max_x_extended)]);

    %% Step 4: Calculate number of points based on bridge length
    total_width = max_x_extended - min_x_extended;
    num_points = ceil(total_width / bridge_length) + 1;

    % Adjust bridge length to ensure exact fit
    adjusted_bridge_length = total_width / (num_points - 1);

    disp(['Number of points on upper boundary: ', num2str(num_points)]);
    disp(['Adjusted bridge length for even spacing: ', num2str(adjusted_bridge_length), ' mm']);

    % Generate upper boundary points
    upper_boundary_x = linspace(min_x_extended, max_x_extended, num_points);
    upper_boundary_y = max_y * ones(1, num_points);
    scatter(upper_boundary_x, upper_boundary_y, 50, 'r', 'filled');

    % Label upper boundary points with odd numbers
    upper_labels = 1:2:2*num_points;
    for i = 1:num_points
        text(upper_boundary_x(i), upper_boundary_y(i)+0.2, num2str(upper_labels(i)), 'FontSize', 10, 'FontWeight', 'bold');
    end

    %% Step 5: Generate 2D Mesh with Intersection Points
    [lines, line_from_points] = generateMeshWithIntersections(upper_boundary_x, upper_boundary_y, min_y, min_x_extended, ...
        max_x_extended, num_points, theta_rad);
    
    %% Step 6: Compute Intersection Points for All Lines
    [all_points, all_intersection_info,combined_points] = computeIntersectionPoints(num_points, upper_boundary_x, ...
        upper_boundary_y, upper_labels, lines, line_from_points, x_shape, y_shape, min_x_extended, max_x_extended, min_y, max_y);
   
    %% Step 7: Prepare for Connectivity Analysis - Use ALL points inside the bounding box
    % Get labels for all points
    all_labels = all_intersection_info(:, 4);

    % Get all intersection points
    intersection_points = all_points(all_intersection_info(:, 3) == 1, :);
    intersection_labels = all_labels(all_intersection_info(:, 3) == 1);

    % Get boundary points
    boundary_points = all_points(all_intersection_info(:, 3) == 0, :);
    boundary_labels = all_labels(all_intersection_info(:, 3) == 0);

    %% Step 8: Build Connectivity Lists
    % Call the function to build connectivity lists
    [connectivity_list, connectivity, unique_connections, adjacency_matrix] = buildConnectivityLists(all_points, all_labels);

    % Store for later use
    connectivity_array = connectivity_list;       

    %Extrude 2D Mesh into 3D
    num_nodes = size(all_points, 1);
    
    %% Step 9: Create the coords matrix with labeled indices and their coordinates
    % Format: [label, x, y, z] for base nodes only (z=0)
    coords = zeros(num_nodes, 4);  % Pre-allocate for base nodes only

    % Store only base nodes with z=0
    for i = 1:num_nodes
        coords(i, :) = [all_labels(i), all_points(i,1), all_points(i,2), 0];
    end

    disp('Created the coords matrix with format: [label, x, y, z] for base nodes only');
    disp(['Size of coords matrix: ', num2str(size(coords,1)), ' x ', num2str(size(coords,2))]);

    %% Step 10: Compute Outer Boundary
    k_boundary = boundary(all_points(:,1), all_points(:,2), 0.9);
end

    %% Step 11: Export to OBJ for ParaView
    obj_filename = 'mesh5_45_outputs.obj';
    exportToOBJ(coords, connectivity, obj_filename);

%% Helper function for line intersection
function [x, y, is_intersect] = line_intersection(p1, p2, p3, p4)
    % Calculate intersection of line segment p1-p2 with line segment p3-p4
    % Returns intersection point (x,y) and whether it's a valid intersection
    
    % Line 1 parameters
    A1 = p2(2) - p1(2);
    B1 = p1(1) - p2(1);
    C1 = A1 * p1(1) + B1 * p1(2);
    
    % Line 2 parameters
    A2 = p4(2) - p3(2);
    B2 = p3(1) - p4(1);
    C2 = A2 * p3(1) + B2 * p3(2);
    
    % Calculate determinant
    det = A1 * B2 - A2 * B1;
    
    % Check if lines are parallel
    if abs(det) < 1e-6
        x = NaN;
        y = NaN;
        is_intersect = false;
        return;
    end
    
    % Calculate intersection point
    x = (B2 * C1 - B1 * C2) / det;
    y = (A1 * C2 - A2 * C1) / det;
    
    % Check if intersection is within both line segments
    if x >= min(p1(1), p2(1)) - 1e-6 && x <= max(p1(1), p2(1)) + 1e-6 && ...
       y >= min(p1(2), p2(2)) - 1e-6 && y <= max(p1(2), p2(2)) + 1e-6 && ...
       x >= min(p3(1), p4(1)) - 1e-6 && x <= max(p3(1), p4(1)) + 1e-6 && ...
       y >= min(p3(2), p4(2)) - 1e-6 && y <= max(p3(2), p4(2)) + 1e-6
        is_intersect = true;
    else
        is_intersect = false;
    end
end