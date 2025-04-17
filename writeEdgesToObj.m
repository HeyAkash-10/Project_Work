function writeEdgesToObj(edges, fileID)
if size(edges, 2) ~= 6
 error('Each edge must be a row of 6 elements: [x1 y1 z1 x2 y2 z2]');
end
 vertices = [];
 vertexMap = containers.Map(); % To avoid duplicates
 lines = []; % Store indices of vertex pairs
for i = 1:size(edges, 1)
 v1 = edges(i, 1:3);
 v2 = edges(i, 4:6);
 key1 = sprintf('%.6f_%.6f_%.6f', v1);
 key2 = sprintf('%.6f_%.6f_%.6f', v2);
if ~isKey(vertexMap, key1)
 vertices(end+1, :) = v1;
 vertexMap(key1) = size(vertices, 1);
end
if ~isKey(vertexMap, key2)
 vertices(end+1, :) = v2;
 vertexMap(key2) = size(vertices, 1);
end
 lines(end+1, :) = [vertexMap(key1), vertexMap(key2)];
end
for i = 1:size(vertices, 1)
 fprintf(fileID, 'v %.6f %.6f %.6f\n', vertices(i, :));
end
for i = 1:size(lines, 1)
 fprintf(fileID, 'l %d %d\n', lines(i, 1), lines(i, 2));
end
end