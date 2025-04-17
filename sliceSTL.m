function [edges_on_slice, convexHulls,no_of_slices] = sliceSTL(stlFile, increment_x)
% SLICESTLMODELS - Slices an STL model along the X-axis at given increments
%
% Syntax:
%   [Slices, convexHulls] = sliceSTLModels(stlFile, increment_x)
%
% Inputs:
%   stlFile     - String, path to the STL file
%   increment_x - Double, distance between slices along X-axis
%
% Outputs:
%   Slices      - Structure array containing flattened edge points
%   convexHulls - Convex hull point indices for each slice

% Read STL file
model = stlread(stlFile);
Points = model.Points();
Triangles = model.ConnectivityList();

fv = struct('faces', Triangles, 'vertices', Points);

figure;
trisurf(model.ConnectivityList, model.Points(:, 1), model.Points(:, 2), model.Points(:, 3), ...
    'FaceColor', 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
camlight; lighting phong;
axis equal;
title('CAD Model');

figure;
trisurf(model.ConnectivityList, model.Points(:, 1), model.Points(:, 2), model.Points(:, 3), ...
    'FaceColor', 'cyan', 'FaceAlpha', 0.3);
camlight; lighting phong;
hold on;
axis equal;
xlabel('X'); ylabel('Y'); zlabel('Z');
title('CAD Model with Sliced Layers');

x_values = Points(:, 1);
[~, idx_min] = min(x_values);
[~, idx_max] = max(x_values);
min_x = Points(idx_min, 1);
max_x = Points(idx_max, 1);

NbrOfTriangles = size(Triangles, 1);
index_slice = 1;
Slices = [];
convexHulls = [];

x_values = min_x:increment_x:max_x;
if x_values(end) < max_x
    x_values = [x_values, max_x];
end

for i = 1:length(x_values)
    x = x_values(i);
    planePoint = [x 0 0];
    planeNormal = [1 0 0];

    edges_on_slice = [];
    index_edge = 1;
    flagPoints = [];

    for j = 1:NbrOfTriangles
        idx = Triangles(j, :);
        verts = Points(idx, :);

        [intersectionPoints, intersectionType] = trianglePlaneIntersection3D(planeNormal, planePoint, verts);
        flagPoints = [flagPoints; intersectionPoints];

        if intersectionType == "Intersection along Edge"
            edges_on_slice(index_edge).v1 = intersectionPoints(1, :);
            edges_on_slice(index_edge).v2 = intersectionPoints(2, :);
            index_edge = index_edge + 1;

            % Plot slice lines
            plot3(intersectionPoints(:, 1), intersectionPoints(:, 2), intersectionPoints(:, 3), 'r-', 'LineWidth', 1.5);
        end
    end
    
    % Store convex hull
    if ~isempty(flagPoints)
        hull = convhull(flagPoints(:, 2), flagPoints(:, 3));
        convexHulls(index_slice).points = hull;
    else
        convexHulls(index_slice).points = [];
    end

    % Flatten v1 and v2 into a single Nx3 matrix
    v1_all = [];
    v2_all = [];
    for k = 1:length(edges_on_slice)
        v1_all = [v1_all; edges_on_slice(k).v1];
        v2_all = [v2_all; edges_on_slice(k).v2];
    end
    Slices(index_slice).edges = [v1_all; v2_all];

    index_slice = index_slice + 1;
end
hold off;

no_of_slices=index_slice - 1;
% fprintf('Total number of slices: %d\n', index_slice - 1);

end
