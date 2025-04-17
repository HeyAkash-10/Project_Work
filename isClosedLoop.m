function isClosed = isClosedLoop(edges)
 pointCount = containers.Map();
for i = 1:length(edges)
 p1 = edges(i).v1;
 p2 = edges(i).v2;
 key1 = sprintf('%.6f %.6f %.6f', p1);
 key2 = sprintf('%.6f %.6f %.6f', p2);
if isKey(pointCount, key1)
 pointCount(key1) = pointCount(key1) + 1;
else
 pointCount(key1) = 1;
end
if isKey(pointCount, key2)
 pointCount(key2) = pointCount(key2) + 1;
else
 pointCount(key2) = 1;
end
end
 counts = cell2mat(values(pointCount));
 isClosed = all(counts == 2);
end