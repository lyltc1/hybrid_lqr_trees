% Compass Gait plant
%p = CompassGaitPlant();

%% Get limit cycle initial condition (FILL ME IN) %%%%%%%%%%%%%%%%%%%%%%%%%
%x0 =  [-0.32338855;0.21866879;-0.37718213;-1.0918269]; % Your x0 from part (b) of the problem "Poincare analysis on compass gait"
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Simulate forwards from x0
% xf = strideFunction(p,x0); % Your strideFunction from the previous problem
% 
% % Check that the resulting trajectory is periodic
% if max(abs(xf-x0)) > 1e-4
%     error('Simulating x0 does not result in a limit cycle');
% end

% Simulate forwards from x0 to get the trajectory
%xtraj = simulate(p,[0 1], [1; x0]);

[p,utraj,xtraj,z,traj_opt]=runDircolCycle;


%xtraj = xtraj.traj{1}.trajs{2}; % Extract first part of the trajectory (before collision)
temp1 = xtraj.traj{1};
temp2 = xtraj.traj{2};
temp2 = temp2.shiftTime(-temp1.tspan(2));
temp1 = temp1.shiftTime(temp2.tspan(2));
xtraj = temp2.trajs{2}.append(temp1.trajs{2});

temp1 = utraj.traj{1};
temp2 = utraj.traj{2};
temp2 = temp2.shiftTime(-temp1.tspan(2));
temp1 = temp1.shiftTime(temp2.tspan(2));
utraj = temp2.append(temp1);


ts = xtraj.getBreaks(); % Get time samples of trajectory


%utraj = PPTrajectory(spline(ts,zeros(1,length(ts)))); % Define nominal u(t),
                                                      % which is all zeros since our
                                                      % system was passive                                                      
                                                      
% Set frames
xtraj = xtraj.setOutputFrame(p.modes{1}.getStateFrame);
utraj = utraj.setOutputFrame(p.modes{1}.getInputFrame);


%% Stabilize using tvlqr (Fill in jump equation) %%%%%%%%%%%%%%%%%%%%%%%%%%
% Define Q, Qf, R
Q = diag([10 10 1 1]);
R = 1;
Qf = Q;

options = struct();

converged = false;
%Ad = findAd();
while ~converged
% tvlqr for continuous phase
[tv,V] = tvlqr(p.modes{1},xtraj,utraj,Q,R,Qf,options);
QfV = Qf;

% Jump equation (FILL ME IN) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S_t_plus = V.S.eval(0);
xend = xtraj.eval(ts(end));
[~,~,~,dxp] = p.collisionDynamics(1,0,xend,0); 
Ad = dxp(:,3:end-1);
S_t_minus = Ad'*S_t_plus*Ad;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Set Qf = to S_t_minus

Qf = S_t_minus;
[~,isp] = chol(Qf);



% Check for convergence (FILL ME IN)
norm(Qf - QfV)
if norm(Qf - QfV) < .5*1e-2
    converged = true;
end


end

Qf_converged = Qf;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup tvlqr controller and simulate from x0 (Don't modify this block of code)

% Extend nominal limit cycle a little bit (see footnote at the bottom for
% an explanation of this - feel free to ignore this if you find it confusing
% This is a practical implementation issue.) 
% tExtended = 1.0;                                                  
% xtrajExtended = p.modes{1}.simulate([0 tExtended],[eval(xtraj,0)]); 
% utrajExtended = PPTrajectory(spline(linspace(0,tExtended,100),zeros(1,100)));
% xtrajExtended = xtrajExtended.setOutputFrame(p.modes{1}.getStateFrame);
% utrajExtended = utrajExtended.setOutputFrame(p.modes{1}.getInputFrame);

[tv,V1] = tvlqr(p.modes{1},xtraj,utraj,Q,R,Qf,options);

% Set frames of tvlqr controller
tv = tv.inOutputFrame(p.getInputFrame);
tv = tv.inInputFrame(p.getOutputFrame);

%pmodel = SimulinkModel(p.getModel());
pmodel = p.modes{1};
tv = tv.setInputFrame(pmodel.getOutputFrame);
tv = tv.setOutputFrame(pmodel.getInputFrame);

% Closed loop system (i.e., feedback system with TVLQR controller)
sysClosedLoop = feedback(pmodel,tv);

% Visualizer
v = CompassGaitVisualizer(p);

%% Simulate from x0 (syntax is useful for part (b)) %%%%%%%%%%%%%%%%%%%%%%%
xtrajSim = sysClosedLoop.simulate([0 xtraj.tspan(2)], [xtraj.eval(0)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Play trajectory back
figure;
hold on;
fnplt(xtraj,1);
xtrajSim = xtrajSim.setOutputFrame(p.getOutputFrame);
v.playback(xtrajSim);
for i = 1:10
  
xend = eval(xtrajSim,xtraj.tspan(2));
xbeg = p.collisionDynamics(1,0,xend,0);
xtrajSim = sysClosedLoop.simulate([0 xtraj.tspan(2)], [xbeg ]);
fnplt(xtrajSim,1);

end





%% Footnote (feel free to ignore) %%
% Since the continuous portion of our nominal trajectory is only defined for a finite amount of time
% [0,ts(end)], we need to deal with cases where the compass gait doesn't
% make contact with the ground before ts(end). Our solution here is to
% extend the nominal trajectory (xtrajExtended) a little beyond ts(end) (by just simulating
% the passive system forwards for longer). This is a reasonable thing to do,
% but still somewhat of a hack. However, this is an important
% implementation issue and worth thinking about in practice.
%%

















