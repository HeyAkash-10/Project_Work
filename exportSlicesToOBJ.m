function exportSlicesToOBJ(Slices, filename)
    fileID = fopen(filename, 'w');
    if fileID == -1
        error('Could not open file: %s', filename);
    end

    vertexMap = containers.Map();
    vertices = [];
    lines = [];
    vertexIndex = 1;

    for s = 1:length(Slices)
        edges = Slices(s).edges;

        for i = 1:length(edges)
            v1 = edges(i).v1;
            v2 = edges(i).v2;

            key1 = sprintf('%.6f_%.6f_%.6f', v1);
            key2 = sprintf('%.6f_%.6f_%.6f', v2);

            if ~isKey(vertexMap, key1)
                vertices(end+1, :) = v1;
                vertexMap(key1) = vertexIndex;
                vertexIndex = vertexIndex + 1;
            end

            if ~isKey(vertexMap, key2)
                vertices(end+1, :) = v2;
                vertexMap(key2) = vertexIndex;
                vertexIndex = vertexIndex + 1;
            end

            lines(end+1, :) = [vertexMap(key1), vertexMap(key2)];
        end
    end

    % Write vertices
    for i = 1:size(vertices, 1)
        fprintf(fileID, 'v %.6f %.6f %.6f\n', vertices(i, :));
    end

    % Write edges as lines
    for i = 1:size(lines, 1)
        fprintf(fileID, 'l %d %d\n', lines(i, 1), lines(i, 2));
    end

    fclose(fileID);
    fprintf('OBJ exported: %s\n', filename);
end
