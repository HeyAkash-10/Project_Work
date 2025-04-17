% Code for saving into OBJ file:

%% display mesh and save into obj file
fileID = fopen('line_segments.obj', 'w');
% Counter for the vertices index
vertex_index = 0;
Length=0;
figure
hold on
if(~isempty(coords ))
    for i=1:size( coords, 1) - 1
        src_x = coords(i, 1);src_y = coords(i, 2);src_z =  coords(i, 3);
        tgt_x = coords(i+1, 1);tgt_y = coords(i+1, 2);tgt_z =  coords(i+1, 3);
        Length=Length+sqrt((src_x-tgt_x)^2+(src_y-tgt_y)^2+(src_z-tgt_z)^2);
        plot3([src_x, tgt_x], [src_y, tgt_y], [src_z, tgt_z], 'r-', 'MarkerSize', 10);
        fprintf(fileID, 'v %f %f %f\n', src_x, src_y, src_z);  % Vertex 1
        fprintf(fileID, 'v %f %f %f\n', tgt_x, tgt_y, tgt_z);  % Vertex 2
        % Write the line segment using vertex indices
        vertex_index = vertex_index + 2;  % Two vertices per line segment
        fprintf(fileID, 'l %d %d\n', vertex_index-1, vertex_index);
    end
end
Length
hold off
% Close the file
fclose(fileID);
disp('OBJ file saved as line_segments.obj');