% An example to demonstrate window dynamic mode decomposition
% 
% We take a 2D time varying system given by dx/dt = A(t)x
% where x = [x1,x2]', A(t) = [0,w(t);-w(t),0], 
% w(t)=1+epsilon*t, epsilon=0.1. The slowly time varying eigenvlaues of A(t)
% are pure imaginary, +(1+0.1t)j and -(1+0.1t)j, where j is the imaginary unit.
% 
% At time step k, define two matrix X(k) = [x(k-w+1),x(k-w+2),...,x(k)], 
% Y(k) = [y(k-w+1),y(k-w+2),...,y(k)], that contain the recent w snapshot pairs 
% from a finite time window, we would like to compute Ak = Yk*pinv(Xk). This can 
% be done by brute-force mini-batch DMD, and by efficient rank-2 updating window 
% DMD algrithm. For window DMD, at time k+1, we need to forget the old snapshot 
% pair xold = x(k-w+1), yold = y(k-w+1), and remember the new snapshot pair xnew 
% = x(k+1), ynew = y(k+1). Mini-batch DMD computes DMD matrix by taking the 
% pseudo-inverse directly. Window DMD computes the DMD matrix by using efficient 
% rank-2 update idea.
% 
% We compare the performance of window DMD with the brute-force mini-batch DMD
% approach in terms of tracking time varying eigenvalues, by comparison with 
% the analytical solution. They should agree with each other (up to machine 
% round-offer errors).
%     
% Authors: 
%     Hao Zhang
%     Clarence W. Rowley
%     
% References:
% Zhang, Hao, Clarence W. Rowley, Eric A. Deem, and Louis N. Cattafesta. 
% "Online dynamic mode decomposition for time-varying systems." 
% SIAM Journal on Applied Dynamical Systems 18, no. 3 (2019): 1586-1609.
%         
% Date created: April 2017

% define dynamics
epsilon = 1e-1;
dyn = @(t,x) ([0, 1+epsilon*t; -(1+epsilon*t),0])*x;
% generate data
dt = 1e-1;
tspan = 0:dt:10;
x0 = [1;0];
[tq,xq] = ode45(dyn, tspan, x0);
% extract snapshot pairs
xq = xq'; tq = tq';
x = xq(:,1:end-1); y = xq(:,2:end); time = tq(2:end);
% true dynamics, eigenvalues
[n, m] = size(x);
A = zeros(n,n,m);
evals = zeros(n,m);
for k = 1:m
    A(:,:,k) = [0, 1+epsilon*time(k); -(1+epsilon*time(k)),0]; % continuous time dynamics
    evals(:,k) = eig(A(:,:,k)); % analytical continuous time eigenvalues
end


% visualize snapshots
figure, hold on
plot(tq,xq(1,:),'x-',tq,xq(2,:),'o-','LineWidth',2)
xlabel('Time','Interpreter','latex')
title('Snapshots','Interpreter','latex')
fl = legend('$x_1(t)$','$x_2(t)$');
set(fl,'Interpreter','latex');
box on
set(gca,'FontSize',20,'LineWidth',2)


% mini-batch DMD
w = 10; % storage time window size, store recent w snapshot pairs
AminibatchDMD = zeros(n,n,m);
evalsminibatchDMD = zeros(n,m);
% mini-batch DMD
tic
for k = w+1:m
    AminibatchDMD(:,:,k) = y(:,k-w+1:k)*pinv(x(:,k-w+1:k));
    evalsminibatchDMD(:,k) = log(eig(AminibatchDMD(:,:,k)))/dt;
end
elapsed_time = toc;
fprintf('Mini-batch DMD, w=10, elapsed time: %f seconds\n', elapsed_time)


% window DMD, weighting = 1
evalswindowDMD1 = zeros(n,m);
% creat object and initialize with first w snapshot pairs
wdmd = WindowDMD(n,w,1);
wdmd.initialize(x(:,1:w), y(:,1:w));
% window DMD
tic
for k = w+1:m
    wdmd.update(x(:,k), y(:,k));
    evalswindowDMD1(:,k) = log(eig(wdmd.A))/dt;
end
elapsed_time = toc;
fprintf('Window DMD, w = 10, weighting = 1, elapsed time: %f seconds\n', elapsed_time)

% window DMD, weighting = 0.5
evalswindowDMD2 = zeros(n,m);
% creat object and initialize with first w snapshot pairs
wdmd = WindowDMD(n,w,0.5);
wdmd.initialize(x(:,1:w), y(:,1:w));
% window DMD
tic
for k = w+1:m
    wdmd.update(x(:,k), y(:,k));
    evalswindowDMD2(:,k) = log(eig(wdmd.A))/dt;
end
elapsed_time = toc;
fprintf('Window DMD, w = 10, weighting = 0.5, elapsed time: %f seconds\n', elapsed_time)

% visualize imaginary part of the continous time eigenvalues
% from true, mini-batch, and window
updateindex = w+1:m;
figure, hold on
plot(time,imag(evals(1,:)),'k-','LineWidth',2)
plot(time(updateindex),imag(evalsminibatchDMD(1,updateindex)),'-','LineWidth',2)
plot(time(updateindex),imag(evalswindowDMD1(1,updateindex)),'--','LineWidth',2)
plot(time(updateindex),imag(evalswindowDMD2(1,updateindex)),'--','LineWidth',2)
xlabel('Time','Interpreter','latex'), ylabel('Im($\lambda_{DMD}$)','Interpreter','latex')
fl = legend('True','Mini-batch, $w=10$','Window, $w=10$, $wf=1$','Window, $w=10$, $wf=0.5$');
set(fl,'Interpreter','latex','Location','northwest');
ylim([1,2]), xlim([0,10])
box on
set(gca,'FontSize',20,'LineWidth',2)