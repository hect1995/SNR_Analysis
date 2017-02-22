clc;
% close all;

freq_glonass= [1 -4 5 6 1 -4 5 6 -2 -7 0 -1 -2 -7 0 -1 4 -3 3 2 4 -3 3 2];%per cada satelit plotejo en quina banda est�
fL1_glonass= 1602*1e6 + 562.5*1e3*freq_glonass;
fL2_glonass= 1246*1e6 + 437.5*1e3*freq_glonass;

fL1= 1575.42*1e6; %frequencia de la banda L1
fL2= 1227.60*1e6;
lambda1= physconst('LightSpeed')/fL1; %longitud d'ona de la banda 1
lambda2= physconst('LightSpeed')/fL2;

lambda_l1_glonass= physconst('LightSpeed')./fL1_glonass;
lambda_l2_glonass= physconst('LightSpeed')./fL2_glonass;

SN=1; %1 si vull L1 o 0 si vull L2

% inici= 297;
inici= 5;
final= 11;

vector_1_satelit_1setmana_gps_l1_5_12= [zeros(2,60*24*60*(final+1-inici)); linspace(0,final+1-inici,60*24*60*(final+1-inici)); zeros(2,60*24*60*(final+1-inici));]; %%(1)f (2)azimuth (3)els dies (4)la lambda (5) el terme lineal que s'ha d'afegir per ser L1 o L2
vector_plot_elev_az_snr= zeros(3*200,10000);
index_vector_plot_elev_az_snr= 1;
% fil_az_min=145;fil_az_max=230; %dspres d'analitzar espectogrames he decidit aixo

%fil_az_min=30;fil_az_max=180;
fil_az_min=30;fil_az_max=230;

fil_el_min=5 ; fil_el_max=25;

inici_glonass= 32;

error_dades= 0;
contador_error= 0;

valor_finestra= 400;

% lambda= [lambda1*ones(1,inici_glonass-1),lambda_l1_glonass]; %vector de l'ambdes --> les 31 primeres corresponen a GPS (totes iguals) i les �ltimes a GLONASS

% BD= base_dades();
% BD= BD(:,(BD(end,:)>=inici & BD(end,:)<=final)); %la ultima fila es el dia de l'any
% mitja_BD= mean(BD(1,:));
% y_interpolat_gt= interp1(linspace(0,7,length(BD(1,:))),BD(1,:),vector_1_satelit_1setmana_gps_l1_5_12(3,:));

for doy=inici:final %faig 1 setmana
    year='2017';
    doy=int2str(doy);
    %     station='MAL1';
    station='TARI';
    
    L1_activat=1;
    L2_activat=1;
    mitja_BD= 5;
    load([station year(3:4) doy 'tablegps.mat']);
    % load(['TARI1722structgps'])
    if exist('dataL1L2')==1
        Sats=unique(dataL1L2.prn);
        %intervalepoch= linspace(0,1,24); %de 0 a 1 dividit 24 vegades per separar epochs de 24 hores d'un dia
        %vector_intervals= zeros(length(Sats)+1,length(intervalepoch)-1,2); %una matriu on posare les f mitges obtingudes per a cada satelit (despres de fer el promitg entre tots els trams que composen un satelit). Creo 2 dimensions ja que en la 1era sera per posar la f corresponent per a cada epoch i la 2a per a posar quants vectors de dades en aquella epoch hi havien del satelit en concret
        %vector_intervals(1,:,1)= intervalepoch(1:end-1);%la 1era fila �s per a posar el vector que va de 0 a 1 dividit en 24 peces
        %vector_azimuts= zeros(length(Sats),2); %per a cada satelit posar� el rang d'azimuts que te (en (:,1) per el azimuth m�s baix i en (:,2) per al m�s gran)
        lambda_escollir= [lambda1 lambda2];
        for aux_lambda= 1:2
            lambda= lambda_escollir(aux_lambda)*ones(1,inici_glonass-1); %per a test el vector de lambdes nom�s poso per GPS
            
            
            for i=1:1:inici_glonass-1%length(Sats) %% de 1 a 31 per gps i de 32 a length(Sats) per glonass
                x= dataL1L2.epoch(dataL1L2.prn==Sats(i));
                if aux_lambda ==1
                    y= dataL1L2.sn1(dataL1L2.prn==Sats(i));
                else
                    y= dataL1L2.sn2(dataL1L2.prn==Sats(i));
                end
                elev= dataL1L2.el(dataL1L2.prn==Sats(i));
                azimuth= dataL1L2.az(dataL1L2.prn==Sats(i));
                
                if sum(isnan(y)==0)~=0
                    %% BUSCAR PICS EN ALTURA PER A SEPARAR ELS TRAMS EN VECTORS DIFERENTS
                    [Max,MaxIdx] = findpeaks(elev); %trobo els maxims de la meva senyal d'altura de satellit
                    DataInv = 1.01*max(elev) - elev;
                    [Min,MinIdx] = findpeaks(DataInv); %busco minims
                    vector1= [MaxIdx MinIdx];
                    vector= sort(vector1); %vector conte tots els pics de la meva funci� --> el numero de trams ser� length(vector)+1 ja que haig d'incloure el tram que va desde l'inici fins el primer pic
                    
                    %% PER ELIMINAR ELS SALTS SOBTATS EN L'ALTURA (la altura dels Satel�lits de tant en tant te salts petits sobtats)
                    auxr=length(vector);
                    oo=1;
                    while oo<auxr
                        if vector(oo+1)==vector(oo)+1
                            vector(oo+1)=[];
                            vector(oo)=[];
                            auxr=auxr-2;
                            oo= oo-1;
                        end
                        oo=oo+1;
                    end
                    %% DEFINEIXO EL VECTOR DE W'S A PARTIR DEL RANG D'ALTURES
                    altura_probable= linspace(6.5,10.5,5000); %de 6.5 a 10.5 metres i 5000 punts en total
                    f= (2/lambda(i)).*altura_probable;
                    %% COMEN�O A EVALUAR CADA TRAM DE UN SATEL�LIT EN CONCRET
                    for tram=0:length(vector) %evaluo cada tram per separat a la resta. Creare 3 possibilitats: que sigui el 1er tram, que sigui un tram del mitg i que sigui l'�ltim tram
                        if isempty(vector)==1
                            vector= length(x);
                        end
                        if tram==0 %1er tram
                            x_vector= x(1:vector(1)); %nomes em quedo amb les mostres del senyal corresponents al 1er tram
                            y_vector= y(1:vector(1));
                            elev_vector= elev(1:vector(1));
                            azim_vector= azimuth(1:vector(1));
                            %% APLICO FUNCIO FILTRE
                            [ SNR_vector, tn_vector, reduit_x_vector, reduit_azim_vector, reduit_elev_vector ]= filtre( x_vector,y_vector,elev_vector,azim_vector,fil_az_min,fil_az_max,fil_el_max,fil_el_min);
                            if L1_activat==1
                                if length(tn_vector)> valor_finestra
                                    vector_1_satelit_1setmana_gps_l1_5_12= spectrograma_2_map_altre(aux_lambda,fil_az_min , fil_az_max , fil_el_min , fil_el_max,i,tram,lambda(i),tn_vector,f,SNR_vector,reduit_x_vector,reduit_azim_vector,reduit_elev_vector,mitja_BD,vector_1_satelit_1setmana_gps_l1_5_12,inici,doy);                                %contador_error= contador_error_meves + contador_error;
                                end
                            end
                        elseif tram==length(vector) % el �ltim subtram
                            x_vector= x(vector(tram) + 1:end);
                            y_vector= y(vector(tram) + 1:end);
                            elev_vector= elev(vector(tram) + 1:end);
                            azim_vector= azimuth(vector(tram) + 1:end);
                            
                            %% APLICO FUNCIO FILTRE
                            [ SNR_vector, tn_vector, reduit_x_vector, reduit_azim_vector, reduit_elev_vector ]= filtre( x_vector,y_vector,elev_vector,azim_vector,fil_az_min,fil_az_max,fil_el_max,fil_el_min);
                            if L1_activat==1
                                if length(tn_vector)> valor_finestra
                                    vector_1_satelit_1setmana_gps_l1_5_12= spectrograma_2_map_altre(aux_lambda,fil_az_min , fil_az_max , fil_el_min , fil_el_max,i,tram,lambda(i),tn_vector,f,SNR_vector,reduit_x_vector,reduit_azim_vector,reduit_elev_vector,mitja_BD,vector_1_satelit_1setmana_gps_l1_5_12,inici,doy);                                %contador_error= contador_error_meves + contador_error;
                                end
                            end
                        else % els trams del mitg
                            x_vector= x(vector(tram) + 1:vector(tram+1));
                            y_vector= y(vector(tram) + 1:vector(tram+1));
                            elev_vector= elev(vector(tram) + 1:vector(tram+1));
                            azim_vector= azimuth(vector(tram) + 1:vector(tram+1));
                            x_vector_aux= x_vector;
                            y_vector_aux= y_vector;
                            auxiliar= 0;
                            
                            %% APLICO FUNCIO FILTRE
                            [ SNR_vector, tn_vector, reduit_x_vector, reduit_azim_vector, reduit_elev_vector ]= filtre( x_vector,y_vector,elev_vector,azim_vector,fil_az_min,fil_az_max,fil_el_max,fil_el_min);
                            
                            if L1_activat==1
                                if length(tn_vector)> valor_finestra
                                    vector_1_satelit_1setmana_gps_l1_5_12= spectrograma_2_map_altre(aux_lambda,fil_az_min , fil_az_max , fil_el_min , fil_el_max,i,tram,lambda(i),tn_vector,f,SNR_vector,reduit_x_vector,reduit_azim_vector,reduit_elev_vector,mitja_BD,vector_1_satelit_1setmana_gps_l1_5_12,inici,doy);
                                    %contador_error= contador_error_meves + contador_error;
                                end
                                
                            end
                        end
                    end
                end
            end
        end
    end
end


vector_1_satelit_1setmana_gps_l1_5_12(1,:)= (vector_1_satelit_1setmana_gps_l1_5_12(1,:).*vector_1_satelit_1setmana_gps_l1_5_12(4,:)./2)-vector_1_satelit_1setmana_gps_l1_5_12(5,:); %converteixo f a altures
vector_1_satelit_1setmana_gps_l1_5_12(1,vector_1_satelit_1setmana_gps_l1_5_12(1,:)==0)= NaN;
% vector_1_satelit_1setmana_gps_l1_5_12(1,vector_1_satelit_1setmana_gps_l1_5_12(1,:)>mitja_BD+3)= NaN; %afegit
% vector_1_satelit_1setmana_gps_l1_5_12(1,vector_1_satelit_1setmana_gps_l1_5_12(1,:)<mitja_BD-2)= NaN; %afegit
%vector_1_satelit_1setmana_gps_l1_5_12 (2,(vector_1_satelit_1setmana_gps_l1_5_12(2,:)<fil_az_min | vector_1_satelit_1setmana_gps_l1_5_12(2,:)>fil_az_max ))= NaN;

save vector_1_satelit_1setmana_gps_l1_5_12.mat


sz=10;
figure;
% scatter(vector_1_satelit_1setmana_gps_l1_5_12(3,:),vector_1_satelit_1setmana_gps_l1_5_12(1,:),sz,vector_1_satelit_1setmana_gps_l1_5_12 (2,:)),c= colorbar,c.Limits= [fil_az_min,fil_az_max],c.LimitsMode='manual';
scatter(vector_1_satelit_1setmana_gps_l1_5_12(3,:),vector_1_satelit_1setmana_gps_l1_5_12(1,:),sz+10,'r','filled');

hold on
eix_x= BD(4,:)-inici;
x1=[BD(1,:);zeros(5*60-1,length(eix_x))]; %simplement faig aquestes 3 linees perque la base de dades que em van passar desde Puertos �s cada 5 minuts i com jo el meu eix es cada segon afageixo 4 0's entre cada xifra per a tenir les mateixes dimensions.
eixy_definitiu=x1(1:end);
eixy_definitiu(eixy_definitiu==0)= NaN;
scatter(vector_1_satelit_1setmana_gps_l1_5_12(3,:),eixy_definitiu,sz,'k','filled') %el de ground truth
title('GPS L1&L2 [5:12] & Ground Truth','FontSize',16);
xlabel('Days of the week','FontSize',16);
ylabel('h[m]','FontSize',16);
set(gca,'fontsize',18)
% legend({'GPS','GT'},'Location','southwest','FontSize',11,'TextColor','black')
grid on;

%% ANALISIS ESTADISTIC ENTRE BASE DE DADES I OBTINGUT PER MI
y_interpolat_gt= interp1(linspace(0,final+1-inici,length(BD(1,:))),BD(1,:),vector_1_satelit_1setmana_gps_l1_5_12(3,:));
error= abs(vector_1_satelit_1setmana_gps_l1_5_12(1,isnan(vector_1_satelit_1setmana_gps_l1_5_12(1,:))==0) - y_interpolat_gt(1,isnan(vector_1_satelit_1setmana_gps_l1_5_12(1,:))==0));
error_mitg= sum(error)/(sum(isnan(vector_1_satelit_1setmana_gps_l1_5_12(1,:))==0));
error_mitg= error_dades/contador_error;
Y = sprintf('El error mitg en dades en metres es: %s',num2str(error_mitg));
disp(Y)
%% CORRELACI�
correlacio= corrcoef(y_interpolat_gt(1,isnan(vector_1_satelit_1setmana_gps_l1_5_12(1,:))==0),vector_1_satelit_1setmana_gps_l1_5_12(1,isnan(vector_1_satelit_1setmana_gps_l1_5_12(1,:))==0));
%% COVERAGE
percent_dades= sum(isnan(vector_1_satelit_1setmana_gps_l1_5_12(1,:))==0)/length(vector_1_satelit_1setmana_gps_l1_5_12(1,:));
coverage_en_s= 1/percent_dades;
X = sprintf('El coverage mitg en dades en segons es: %d',coverage_en_s);
disp(X)









