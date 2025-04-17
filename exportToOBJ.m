function exportToOBJ(coords, connectivity, filename)
    % Function to export mesh as OBJ file for ParaView
    % coords: [label, x, y, z] matrix of vertex coordinates
    % connectivity: structure containing connectivity information
    
    % Open the file for writing
    fileID = fopen(filename, 'w');
    
    % Write vertex data (ignore the label in coords, use only x,y,z)
    for i = 1:size(coords, 1)
        fprintf(fileID, 'v %.6f %.6f %.6f\n', coords(i, 2), coords(i, 3), coords(i, 4));
    end
    
    % Create mapping from labels to vertex indices
    label_to_idx = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for i = 1:size(coords, 1)
        label_to_idx(coords(i, 1)) = i;
    end
    
    % Write line connectivity data
    % First check what fields are in the connectivity structure
    if isstruct(connectivity)
        % If it's a structure, use appropriate fields
        field_names = fieldnames(connectivity);
        disp('Connectivity structure fields:');
        disp(field_names);
        
        % Try to identify the field with connectivity information
        for i = 1:length(field_names)
            field_data = connectivity.(field_names{i});
            if iscell(field_data)
                for j = 1:length(field_data)
                    if length(field_data{j}) >= 2
                        % Assume this is an edge connecting two points
                        edge_vertices = field_data{j};
                        for k = 1:length(edge_vertices)-1
                            start_vertex = edge_vertices(k);
                            end_vertex = edge_vertices(k+1);
                            
                            if isKey(label_to_idx, start_vertex) && isKey(label_to_idx, end_vertex)
                                start_idx = label_to_idx(start_vertex);
                                end_idx = label_to_idx(end_vertex);
                                fprintf(fileID, 'l %d %d\n', start_idx, end_idx);
                            end
                        end
                    end
                end
            elseif isnumeric(field_data) && size(field_data, 2) >= 2
                % Handle numeric array of edges
                for j = 1:size(field_data, 1)
                    start_vertex = field_data(j, 1);
                    end_vertex = field_data(j, 2);
                    
                    if isKey(label_to_idx, start_vertex) && isKey(label_to_idx, end_vertex)
                        start_idx = label_to_idx(start_vertex);
                        end_idx = label_to_idx(end_vertex);
                        fprintf(fileID, 'l %d %d\n', start_idx, end_idx);
                    end
                end
            end
        end
    elseif iscell(connectivity)
        % Handle cell array connectivity
        for i = 1:length(connectivity)
            if length(connectivity{i}) >= 2
                edge_vertices = connectivity{i};
                for j = 1:length(edge_vertices)-1
                    start_vertex = edge_vertices(j);
                    end_vertex = edge_vertices(j+1);
                    
                    if isKey(label_to_idx, start_vertex) && isKey(label_to_idx, end_vertex)
                        start_idx = label_to_idx(start_vertex);
                        end_idx = label_to_idx(end_vertex);
                        fprintf(fileID, 'l %d %d\n', start_idx, end_idx);
                    end
                end
            end
        end
    elseif isnumeric(connectivity)
        % Handle numeric array connectivity
        for i = 1:size(connectivity, 1)
            if size(connectivity, 2) >= 2
                start_vertex = connectivity(i, 1);
                end_vertex = connectivity(i, 2);
                
                if isKey(label_to_idx, start_vertex) && isKey(label_to_idx, end_vertex)
                    start_idx = label_to_idx(start_vertex);
                    end_idx = label_to_idx(end_vertex);
                    fprintf(fileID, 'l %d %d\n', start_idx, end_idx);
                end
            end
        end
    else
        disp('Warning: Connectivity format not recognized');
    end
    
    % Close the file
    fclose(fileID);
    
    disp(['Mesh exported to ', filename]);
    disp('Connectivity type:');
    disp(class(connectivity));
    if ~isstruct(connectivity) && ~iscell(connectivity) && ~isnumeric(connectivity)
        disp('Connectivity format not supported');
    end
end