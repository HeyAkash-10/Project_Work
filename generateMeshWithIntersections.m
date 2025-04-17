function [lines, line_from_points] = generateMeshWithIntersections(upper_boundary_x, upper_boundary_y, min_y, min_x_extended, ...
    max_x_extended, num_points, theta_rad)
%GENERATEMESHWITHINTERSECTIONS Generates 2D mesh with lines from upper boundary
%   Outputs:
%   - lines: Matrix of line parameters [m, c, x_start, y_start, x_end_acute/obtuse, y_end_acute/obtuse]
%   - line_from_points: Matrix tracking which boundary point each line came from [point_index, is_obtuse]

    % Initialize arrays
    lines = [];
    line_from_points = []; % Store which boundary point each line came from

    % Loop through each point on the upper boundary
    for i = 1:num_points
        x_start = upper_boundary_x(i);
        y_start = upper_boundary_y(i);

        % Calculate end points for acute and obtuse angle lines
        x_end_acute = x_start + (upper_boundary_y(i) - min_y) * tan(theta_rad);
        y_end_acute = min_y;
        x_end_obtuse = x_start - (upper_boundary_y(i) - min_y) * tan(theta_rad);
        y_end_obtuse = min_y;

        % Adjust endpoints if they extend beyond the bounding box
        if x_end_acute > max_x_extended
            x_end_acute = max_x_extended;
            y_end_acute = y_start - (x_end_acute - x_start) / tan(theta_rad);
        end
        if x_end_obtuse < min_x_extended
            x_end_obtuse = min_x_extended;
            y_end_obtuse = y_start - (x_start - x_end_obtuse) / tan(theta_rad);
        end

        % Calculate slope and y-intercept for acute angle line
        m_acute = (y_end_acute - y_start) / (x_end_acute - x_start);
        c_acute = y_start - m_acute * x_start;
        lines = [lines; m_acute, c_acute, x_start, y_start, x_end_acute, y_end_acute];
        line_from_points = [line_from_points; i, 0]; % 0 for acute angle line

        % Calculate slope and y-intercept for obtuse angle line
        m_obtuse = (y_end_obtuse - y_start) / (x_end_obtuse - x_start);
        c_obtuse = y_start - m_obtuse * x_start;
        lines = [lines; m_obtuse, c_obtuse, x_start, y_start, x_end_obtuse, y_end_obtuse];
        line_from_points = [line_from_points; i, 1]; % 1 for obtuse angle line

        % Plot the lines on the current figure
        plot([x_start, x_end_acute], [y_start, y_end_acute], 'g-', 'LineWidth', 1.5);
        plot([x_start, x_end_obtuse], [y_start, y_end_obtuse], 'm-', 'LineWidth', 1.5);
    end
end