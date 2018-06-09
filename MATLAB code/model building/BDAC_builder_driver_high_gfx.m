function [pop, stat] = BDAC_builder_driver_high_gfx( val, label, seed_centers, globalvars )

% setup simulation parameters
              % Number of neighbors to consider



end_time = globalvars.end_time;    % end time
dt = globalvars.dt;                % time step
steps = end_time / dt;  % we'll use linear steps
NN= globalvars.NN;
 
globalvars.centers = seed_centers;

globalvars.val = val;

%units of distance is 1 nm
globalvars.coreR = 48;      % radius of PS sphere
globalvars.eq_size = 13;    % Bead radius
[beads,trash] = size(globalvars.centers);
globalvars.bounds = [-10000,10000;-10000,10000; -10000,10000 ]; % 20 micron size
   
for i = 1:beads
    beadList(i) = bead(globalvars.centers(i,:), [0,0,0], i, globalvars.eq_size); %#ok<AGROW>
end

id = i+1;



%record = zeros( steps, 3*beads);

file3d = sprintf('beads3d_%s_%d.avi', label, val );
file3d %#ok<NOPRT>
aviobj3d=avifile(file3d); %creates AVI file

steps_since_recalc = 1e6;
k = 1;
    
for cct = 1:beads
    x(cct, 1:3) = beadList(cct).x;
    x_prime(cct, 1:3) = beadList(cct).x_prime;
    v(cct, 1:3) = beadList(cct).v;
    v_prime(cct, 1:3) = beadList(cct).v_prime;
end

[xs,ys,zs] = sphere(20);
at = zeros( size(x));

for i = 1:steps
        
    
    if (beads > 1 && steps_since_recalc > 20 )
        % Work out the NN. The KNN code used is borrowed, see file for credits.
        if beads < NN
            use_nn = length(beadList);
        else
            use_nn = NN;
        end
        
        dataMatrix = zeros( beads, 3 );
        

        dataMatrix = x;

        
        queryMatrix = dataMatrix;        
        
        [globalvars.neighborIds globalvars.neighborDistances] = kNearestNeighbors(dataMatrix, queryMatrix, use_nn);
        %globalvars.neighborIds
        %stop
        steps_since_recalc = 0;                
    else
        steps_since_recalc = steps_since_recalc+1;
    end

                     
        
    [x, x_prime, v, v_prime] = apply_force_vect_2nd_order_euler( x,  v,  @nn_force_vect2, dt, globalvars );        
    [x, x_prime, v, v_prime] = update_vect2(x, x_prime, v, v_prime, dt);
    
    
    if mod(i,400)==0               
        fprintf('%d of %d\n', i, steps );

                
    
                
        vel = sum(euc_dist(v,0))/beads;
        
        hf= figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off');
        hax=axes;


        h = surf(48*xs,48*ys,48*zs);
        set(h,'Facecolor',[1 0 0])
        l = light;
        lighting phong
        hold on;
        
        for  cc= 1:length(beadList)
            
            h = surf(13*(xs)+x(cc,1),13*(ys)+x(cc,2),13*(zs)+x(cc,3));
            set(h,'Facecolor',[0 1 0])
        end
        
        set(gca,'Xlim',[-250 250]);
        set(gca,'Ylim',[-250 250]);    
        set(gca, 'Zlim', [ -250 250]);
        
        aviobj3d = addframe(aviobj3d, hf);
        close(hf); %closes the handle to invisible figure close all;   

        stat_gen(k,1:2) = [ i*dt, vel ];
        k = k + 1;                
    end
    
    
    
end

aviobj3d=close(aviobj3d); %closes the AVI file

%tic
%M = make_movie( 'test.avi', record );
%toc

% Not that this makes a lot of sense at the moment, but here is the
% feedback.

for cct = 1:beads
    beadList(cct).x = x(cct, 1:3);
    beadList(cct).x_prime = x_prime(cct, 1:3);
    beadList(cct).v = v(cct, 1:3);
    beadList(cct).v_prime = v_prime(cct, 1:3);
end

pop = beadList;
stat = stat_gen;

% figure;
% plot( stat_gen(:,1), stat_gen(:,2), 'xr' );
% figure;
% plot( stat_total_cells(:,1), stat_total_cells(:,2), 'ob' );

clear beadList