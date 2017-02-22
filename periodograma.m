function [ Y ] = periodograma( w1,tn_vectoraux,vq1)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
s=zeros(1,length(w1));
for l = 1:length(w1)
   exponencial = (exp(-1i*tn_vectoraux*w1(l))); 
   s(l) = sum(vq1.*exponencial);  % haig d'afegir el vector de w's a la exponencial 
   exponencial = 0;
end

Y = ((1/length(tn_vectoraux))^2)*(abs(s)).^2;
Y = Y';


% figure;
% plot(w1,Y);
% title('Periodograma ','FontSize',16);
% xlabel('w','FontSize',14);
% ylabel('C/N0','FontSize',14);
% grid on;

end

