function [all_points, all_intersection_info, inside_intersection_points, boundary_points, combined_points] = computeIntersectionPoints(num_points, upper_boundary_x, upper_boundary_y, upper_labels, lines, line_from_points, x_shape, y_shape, min_x_extended, max_x_extended, min_y, max_y)
    % Initialize arrays to store all points
    all_points = [];
    all_intersection_info = []; % Store boundary point number and intersection info
    inside_intersection_points = []; % Store intersection points inside the polygon
    boundary_points = []; % Store boundary points on the polygon boundary
    combined_points = []; % New array to store both boundary and inside points in sequential order
    current_label = 2; % Start with even number 2 for intersection points

    % Helper function for line intersection
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

    % Helper function to check if a point is on the polygon boundary
    function is_on_boundary = isOnPolygonBoundary(x, y, x_shape, y_shape)
        is_on_boundary = false;
        
        % Check each edge of the polygon
        for k = 1:length(x_shape)-1
            x1 = x_shape(k);
            y1 = y_shape(k);
            x2 = x_shape(k+1);
            y2 = y_shape(k+1);
            
            % Check if point lies on the line segment
            if abs((y2-y1)*(x-x1) - (x2-x1)*(y-y1)) < 1e-6 && ...
               x >= min(x1, x2) - 1e-6 && x <= max(x1, x2) + 1e-6 && ...
               y >= min(y1, y2) - 1e-6 && y <= max(y1, y2) + 1e-6
                is_on_boundary = true;
                return;
            end
        end
    end
    
    % Add all polygon corner points to combined_points first
    % Start with a new sequential label after the boundary points
    corner_label_start = max(upper_labels) + 2;
    for i = 1:length(x_shape)-1  % Skip the last point as it's the same as the first for closed polygon
        corner_x = x_shape(i);
        corner_y = y_shape(i);
        
        % Check if this corner is already an upper boundary point
        is_upper_boundary = false;
        matching_upper_idx = 0;
        
        for j = 1:num_points
            if abs(corner_x - upper_boundary_x(j)) < 1e-6 && abs(corner_y - upper_boundary_y(j)) < 1e-6
                is_upper_boundary = true;
                matching_upper_idx = j;
                break;
            end
        end
        
        if is_upper_boundary
            % If it's already an upper boundary point, use its label
            corner_label = upper_labels(matching_upper_idx);
        else
            % Otherwise assign a new label
            corner_label = corner_label_start;
            corner_label_start = corner_label_start + 2; % Keep even numbers for new points
        end
        
        % Add to boundary_points
        boundary_points = [boundary_points; corner_x, corner_y, corner_label];
        
        % Add to combined_points
        combined_points = [combined_points; corner_x, corner_y, corner_label];
    end

    % Process in order of upper boundary points with odd numbers (1, 3, 5, etc.)
    for boundary_idx = 1:num_points
        % Current boundary point label
        boundary_label = upper_labels(boundary_idx);
        % disp(['Processing boundary point ', num2str(boundary_label), ':']);
        
        % Add the boundary point to all_points
        x_boundary = upper_boundary_x(boundary_idx);
        y_boundary = upper_boundary_y(boundary_idx);
        all_points = [all_points; x_boundary, y_boundary];
        all_intersection_info = [all_intersection_info; boundary_idx, 0, 0, boundary_label]; % 0 indicates boundary point
        
        % Check if boundary point is on the polygon boundary
        if isOnPolygonBoundary(x_boundary, y_boundary, x_shape, y_shape)
            boundary_points = [boundary_points; x_boundary, y_boundary, boundary_label];
            
            % Check if this boundary point is already in combined_points (to avoid duplicates)
            already_in_combined = false;
            for i = 1:size(combined_points, 1)
                if abs(combined_points(i,1) - x_boundary) < 1e-6 && abs(combined_points(i,2) - y_boundary) < 1e-6
                    already_in_combined = true;
                    break;
                end
            end
            
            % Add to combined_points if not already there
            if ~already_in_combined
                combined_points = [combined_points; x_boundary, y_boundary, boundary_label];
            end
        end
        
        % disp(['  Boundary point ' num2str(boundary_label) ': (', num2str(x_boundary), ', ', num2str(y_boundary), ')']);
        
        % Find the acute angle line from this boundary point (green line)
        acute_line_idx = find(line_from_points(:,1) == boundary_idx & line_from_points(:,2) == 0);
        
        if ~isempty(acute_line_idx)
            % Get line parameters
            line_i = lines(acute_line_idx,:);
            m1 = line_i(1);
            c1 = line_i(2);
            x_start_i = line_i(3);
            y_start_i = line_i(4);
            x_end_i = line_i(5);
            y_end_i = line_i(6);
            
            % Find intersections with all other lines
            line_intersections = [];
            
            % 1. Check intersections with all other lines
            for j = 1:size(lines, 1)
                % Skip if it's the same line
                if acute_line_idx == j
                    continue;
                end
                
                % Get parameters of the other line
                line_j = lines(j,:);
                m2 = line_j(1);
                c2 = line_j(2);
                x_start_j = line_j(3);
                y_start_j = line_j(4);
                x_end_j = line_j(5);
                y_end_j = line_j(6);
                
                % Check if lines are nearly parallel
                if abs(m1 - m2) > 1e-6
                    % Calculate intersection
                    x_intersect = (c2 - c1) / (m1 - m2);
                    y_intersect = m1 * x_intersect + c1;
                    
                    % Check if intersection point is on both line segments
                    on_segment_i = (x_intersect >= min(x_start_i, x_end_i) - 1e-6) && ...
                                   (x_intersect <= max(x_start_i, x_end_i) + 1e-6) && ...
                                   (y_intersect >= min(y_start_i, y_end_i) - 1e-6) && ...
                                   (y_intersect <= max(y_start_i, y_end_i) + 1e-6);
                                   
                    on_segment_j = (x_intersect >= min(x_start_j, x_end_j) - 1e-6) && ...
                                   (x_intersect <= max(x_start_j, x_end_j) + 1e-6) && ...
                                   (y_intersect >= min(y_start_j, y_end_j) - 1e-6) && ...
                                   (y_intersect <= max(y_start_j, y_end_j) + 1e-6);
                    
                    % If on both segments, add to line_intersections
                    if on_segment_i && on_segment_j
                        line_intersections = [line_intersections; x_intersect, y_intersect, j];
                    end
                end
            end
            
            % 2. Find intersections with the polygon boundary
            for j = 1:length(x_shape)-1
                % Boundary segment endpoints
                boundary_x1 = x_shape(j);
                boundary_y1 = y_shape(j);
                boundary_x2 = x_shape(j+1);
                boundary_y2 = y_shape(j+1);
                
                % Calculate intersection with boundary segment
                [xi, yi, is_intersect] = line_intersection([x_start_i, y_start_i], [x_end_i, y_end_i], ...
                                                         [boundary_x1, boundary_y1], [boundary_x2, boundary_y2]);
                
                % If valid intersection exists
                if is_intersect
                    line_intersections = [line_intersections; xi, yi, -j]; % Negative j to indicate polygon boundary
                end
            end
            
            % 3. Sort intersections by distance from boundary point
            distances = zeros(size(line_intersections, 1), 1);
            for j = 1:size(line_intersections, 1)
                distances(j) = sqrt((line_intersections(j,1) - x_start_i)^2 + (line_intersections(j,2) - y_start_i)^2);
            end
            
            [~, sorted_idx] = sort(distances);
            sorted_intersections = line_intersections(sorted_idx, :);
            
            % 4. Add sorted intersections to all_points
            for j = 1:size(sorted_intersections, 1)
                x_int = sorted_intersections(j, 1);
                y_int = sorted_intersections(j, 2);
                line_idx = sorted_intersections(j, 3);
                
                % Check if point is already in all_points (avoid duplicates)
                if ~any(all(abs(all_points(:,1:2) - [x_int, y_int]) < 1e-6, 2))
                    % Determine if the point is inside the bounding box
                    in_bbox = (x_int >= min_x_extended - 1e-6) && (x_int <= max_x_extended + 1e-6) && ...
                              (y_int >= min_y - 1e-6) && (y_int <= max_y + 1e-6);
                    
                    if in_bbox
                        % Check if point is inside or on the polygon
                        is_inside = inpolygon(x_int, y_int, x_shape, y_shape);
                        is_on_boundary = isOnPolygonBoundary(x_int, y_int, x_shape, y_shape);
                        
                        % Assign even-numbered label to intersection point
                        point_label = current_label;
                        current_label = current_label + 2; % Increment by 2 to keep even numbers
                        
                        all_points = [all_points; x_int, y_int];
                        all_intersection_info = [all_intersection_info; boundary_idx, line_idx, 1, point_label]; % 1 indicates intersection
                        
                        if is_inside
                            % disp(['  Inside intersection: (', num2str(x_int), ', ', num2str(y_int), '), Label: ', num2str(point_label)]);
                            scatter(x_int, y_int, 50, 'b', 'filled');
                            % Add inside intersection point to the dedicated array
                            inside_intersection_points = [inside_intersection_points; x_int, y_int, point_label];
                            
                            % Check if intersection point is already in combined_points
                            already_in_combined = false;
                            for k = 1:size(combined_points, 1)
                                if abs(combined_points(k,1) - x_int) < 1e-6 && abs(combined_points(k,2) - y_int) < 1e-6
                                    already_in_combined = true;
                                    break;
                                end
                            end
                            
                            % Add to combined_points if not already there
                            if ~already_in_combined
                                combined_points = [combined_points; x_int, y_int, point_label];
                            end
                            
                            % If the point is also on the boundary, add it to boundary_points
                            if is_on_boundary
                                boundary_points = [boundary_points; x_int, y_int, point_label];
                                % Point already added to combined_points above
                            end
                        else
                            % disp(['  Outside intersection: (', num2str(x_int), ', ', num2str(y_int), '), Label: ', num2str(point_label)]);
                            scatter(x_int, y_int, 50, 'g', 'filled');
                            
                            % If point is on boundary but not inside, still add to boundary_points
                            if is_on_boundary
                                boundary_points = [boundary_points; x_int, y_int, point_label];
                                
                                % Check if point is already in combined_points
                                already_in_combined = false;
                                for k = 1:size(combined_points, 1)
                                    if abs(combined_points(k,1) - x_int) < 1e-6 && abs(combined_points(k,2) - y_int) < 1e-6
                                        already_in_combined = true;
                                        break;
                                    end
                                end
                                
                                % Add to combined_points if not already there
                                if ~already_in_combined
                                    combined_points = [combined_points; x_int, y_int, point_label];
                                end
                            end
                        end
                        
                        % Label the intersection point
                        text(x_int, y_int+0.2, num2str(point_label), 'FontSize', 10, 'FontWeight', 'bold');
                    end
                end
            end
        end
        
        % Now do the same for obtuse angle line (magenta line)
        obtuse_line_idx = find(line_from_points(:,1) == boundary_idx & line_from_points(:,2) == 1);
        
        if ~isempty(obtuse_line_idx)
            % Get line parameters
            line_i = lines(obtuse_line_idx,:);
            m1 = line_i(1);
            c1 = line_i(2);
            x_start_i = line_i(3);
            y_start_i = line_i(4);
            x_end_i = line_i(5);
            y_end_i = line_i(6);
            
            % Find intersections with all other lines
            line_intersections = [];
            
            % 1. Check intersections with all other lines
            for j = 1:size(lines, 1)
                % Skip if it's the same line
                if obtuse_line_idx == j
                    continue;
                end
                
                % Get parameters of the other line
                line_j = lines(j,:);
                m2 = line_j(1);
                c2 = line_j(2);
                x_start_j = line_j(3);
                y_start_j = line_j(4);
                x_end_j = line_j(5);
                y_end_j = line_j(6);
                
                % Check if lines are nearly parallel
                if abs(m1 - m2) > 1e-6
                    % Calculate intersection
                    x_intersect = (c2 - c1) / (m1 - m2);
                    y_intersect = m1 * x_intersect + c1;
                    
                    % Check if intersection point is on both line segments
                    on_segment_i = (x_intersect >= min(x_start_i, x_end_i) - 1e-6) && ...
                                   (x_intersect <= max(x_start_i, x_end_i) + 1e-6) && ...
                                   (y_intersect >= min(y_start_i, y_end_i) - 1e-6) && ...
                                   (y_intersect <= max(y_start_i, y_end_i) + 1e-6);
                                   
                    on_segment_j = (x_intersect >= min(x_start_j, x_end_j) - 1e-6) && ...
                                   (x_intersect <= max(x_start_j, x_end_j) + 1e-6) && ...
                                   (y_intersect >= min(y_start_j, y_end_j) - 1e-6) && ...
                                   (y_intersect <= max(y_start_j, y_end_j) + 1e-6);
                    
                    % If on both segments, add to line_intersections
                    if on_segment_i && on_segment_j
                        line_intersections = [line_intersections; x_intersect, y_intersect, j];
                    end
                end
            end
            
            % 2. Find intersections with the polygon boundary
            for j = 1:length(x_shape)-1
                % Boundary segment endpoints
                boundary_x1 = x_shape(j);
                boundary_y1 = y_shape(j);
                boundary_x2 = x_shape(j+1);
                boundary_y2 = y_shape(j+1);
                
                % Calculate intersection with boundary segment
                [xi, yi, is_intersect] = line_intersection([x_start_i, y_start_i], [x_end_i, y_end_i], ...
                                                         [boundary_x1, boundary_y1], [boundary_x2, boundary_y2]);
                
                % If valid intersection exists
                if is_intersect
                    line_intersections = [line_intersections; xi, yi, -j]; % Negative j to indicate polygon boundary
                end
            end
            
            % 3. Sort intersections by distance from boundary point
            distances = zeros(size(line_intersections, 1), 1);
            for j = 1:size(line_intersections, 1)
                distances(j) = sqrt((line_intersections(j,1) - x_start_i)^2 + (line_intersections(j,2) - y_start_i)^2);
            end
            
            [~, sorted_idx] = sort(distances);
            sorted_intersections = line_intersections(sorted_idx, :);
            
            % 4. Add sorted intersections to all_points
            for j = 1:size(sorted_intersections, 1)
                x_int = sorted_intersections(j, 1);
                y_int = sorted_intersections(j, 2);
                line_idx = sorted_intersections(j, 3);
                
                % Check if point is already in all_points (avoid duplicates)
                if ~any(all(abs(all_points(:,1:2) - [x_int, y_int]) < 1e-6, 2))
                    % Determine if the point is inside the bounding box
                    in_bbox = (x_int >= min_x_extended - 1e-6) && (x_int <= max_x_extended + 1e-6) && ...
                              (y_int >= min_y - 1e-6) && (y_int <= max_y + 1e-6);
                    
                    if in_bbox
                        % Check if point is inside or on the polygon
                        is_inside = inpolygon(x_int, y_int, x_shape, y_shape);
                        is_on_boundary = isOnPolygonBoundary(x_int, y_int, x_shape, y_shape);
                        
                        % Assign even-numbered label to intersection point
                        point_label = current_label;
                        current_label = current_label + 2; % Increment by 2 to keep even numbers
                        
                        all_points = [all_points; x_int, y_int];
                        all_intersection_info = [all_intersection_info; boundary_idx, line_idx, 1, point_label]; % 1 indicates intersection
                        
                        if is_inside
                            % disp(['  Inside intersection: (', num2str(x_int), ', ', num2str(y_int), '), Label: ', num2str(point_label)]);
                            scatter(x_int, y_int, 50, 'b', 'filled');
                            % Add inside intersection point to the dedicated array
                            inside_intersection_points = [inside_intersection_points; x_int, y_int, point_label];
                            
                            % Check if point is already in combined_points
                            already_in_combined = false;
                            for k = 1:size(combined_points, 1)
                                if abs(combined_points(k,1) - x_int) < 1e-6 && abs(combined_points(k,2) - y_int) < 1e-6
                                    already_in_combined = true;
                                    break;
                                end
                            end
                            
                            % Add to combined_points if not already there
                            if ~already_in_combined
                                combined_points = [combined_points; x_int, y_int, point_label];
                            end
                            
                            % If the point is also on the boundary, add it to boundary_points
                            if is_on_boundary
                                boundary_points = [boundary_points; x_int, y_int, point_label];
                                % Point already added to combined_points above
                            end
                        else
                            % disp(['  Outside intersection: (', num2str(x_int), ', ', num2str(y_int), '), Label: ', num2str(point_label)]);
                            scatter(x_int, y_int, 50, 'g', 'filled');
                            
                            % If point is on boundary but not inside, still add to boundary_points
                            if is_on_boundary
                                boundary_points = [boundary_points; x_int, y_int, point_label];
                                
                                % Check if point is already in combined_points
                                already_in_combined = false;
                                for k = 1:size(combined_points, 1)
                                    if abs(combined_points(k,1) - x_int) < 1e-6 && abs(combined_points(k,2) - y_int) < 1e-6
                                        already_in_combined = true;
                                        break;
                                    end
                                end
                                
                                % Add to combined_points if not already there
                                if ~already_in_combined
                                    combined_points = [combined_points; x_int, y_int, point_label];
                                end
                            end
                        end
                        
                        % Label the intersection point
                        text(x_int, y_int+0.2, num2str(point_label), 'FontSize', 10, 'FontWeight', 'bold');
                    end
                end
            end
        end
    end
end