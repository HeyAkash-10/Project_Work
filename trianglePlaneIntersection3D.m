function [intersectionPoints, intersectionType] = trianglePlaneIntersection3D(planeNormal, planePoint, vertices)
 d = -dot(planeNormal, planePoint);
 distances = zeros(3, 1);
for i = 1:3
 distances(i) = dot(planeNormal, vertices(i, :)) + d;
end
 intersectionPoints = [];
for i = 1:3
 j = mod(i, 3) + 1; % Next vertex index
 lineDir = vertices(j, :) - vertices(i, :);
 t = -(dot(planeNormal, vertices(i, :)) + d) / dot(planeNormal, lineDir);
if t >= 0 && t <= 1
 intersectionPoint = vertices(i, :) + t * lineDir;
 intersectionPoints = [intersectionPoints; intersectionPoint];
end
end
if isempty(intersectionPoints)
 intersectionType = 'No Intersection';
elseif size(intersectionPoints, 1) == 1
 intersectionType = 'Intersection at Vertex';
elseif size(intersectionPoints, 1) == 2
 intersectionType = 'Intersection along Edge';
else
 intersectionType = 'Complex Intersection';
end
end