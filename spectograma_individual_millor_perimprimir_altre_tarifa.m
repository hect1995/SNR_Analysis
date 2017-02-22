function spectograma_individual_millor_perimprimir_altre_tarifa(aux_lambda,SNR_vector,f,tn_vector,reduit_azim_vector,reduit_elev_vector,reduit_x_vector,lambda,doy,tram,satelit,valor_auxiliar,fil_el_max,fil_el_min)

[~,ai,~]= unique(tn_vector);

SNR_vector= SNR_vector(ai);
tn_vector= tn_vector(ai);
reduit_elev_vector= reduit_elev_vector(ai);
reduit_azim_vector= reduit_azim_vector(ai);
reduit_x_vector= reduit_x_vector(ai);

%frequencies va de 3 a 7 --> prenc mesura cada 0.25 --> 16 posicions
altures= [6.5 6.675 6.75 6.875 7 7.125 7.25 7.375 7.5 7.675 7.75 7.875 8 8.125 8.25 8.375 8.5 8.675 8.75 8.875 9 9.125 9.25 9.375 9.5 9.675 9.75 9.875 10 10.125 10.25 10.375 10.5];frequencies=(2/lambda).*altures;
representacio= zeros(length(altures)-1,15000);
reduit_elev_vector_taula=zeros(1,15000);
j=1;
i=1;
contador=1;
window= 500; %la finestra escollida
step= 30; %el step escollit per anar movent el spectograma
auxiliar= 1;
if contador+window  >length(SNR_vector) - 2*step %aixi m'asseguro de tenir suficients dades i no que nomes pugui agafar una subfinestra i que tot peti
    auxiliar =0;
end


while j~=0
    if contador+window - length(SNR_vector) <0
        %% APROXIMACI� POLIN�MICA PER A TREURE LA MITJA AL MEU SNR (FER-LO DE MITJA 0) I TAMB� CREO EL VECTOR TN_VECTOR --> SIND(VECTOR ELEVACIO)
        r= polyfit(tn_vector(contador:contador+window),SNR_vector(contador:contador+window),6);%faig l'aproximaci� polin�mica de grau 6 del tram
        f1 = polyval(r,tn_vector(contador:contador+window));
        auxiliar= SNR_vector(contador:contador+window)- f1; % em quedo amb la diferencia entre el real i l'aproximaci� polin�mica per treure-li la mitja
        SNR_vector(contador:contador+window)= auxiliar - mean(auxiliar); %li torno a treure la mitja per si encara no era diferent de 0
        Y= periodograma(2*pi*f,tn_vector(contador:contador+window),SNR_vector(contador:contador+window)); %el vector a secas (sense interpolar)
        
        for aux=1:length(representacio(:,1))
            frequencies_alta= frequencies(aux+1)*ones(1,length(f));
            frequencies_baixa= frequencies(aux)*ones(1,length(f));
            Y_tram= Y(f<frequencies_alta & f>=frequencies_baixa);
            representacio(aux,i)= mean(Y_tram);
        end
        reduit_elev_vector_taula(i)= reduit_elev_vector(contador+window);
        contador= contador + step ; %per on comen�ar el seguent tram
        i=i+1; %contador per anar afegint subfinestres en representacio i reduit_elev_vector_taula
    else
        j= 0;
    end
end


representacio_final= zeros(length(altures)-1,i-1);
for ii=1:length(altures)-1
    representacio_final(ii,:)= representacio(ii,1:i-1) ;
end

if auxiliar ~= 0
    contador= 1;
    [~,I]= max(representacio_final(:));
    [~, I_col] = ind2sub(size(representacio_final),I); %per trobar la columna amb el maxim
    Y_maxim= periodograma(2*pi*f,tn_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window),SNR_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window)); %per recalcular el periodograma del m�xim, segurament podria ser m�s eficient per� bueno
    temps= mean(reduit_x_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window));
    azimuth= mean(reduit_azim_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window));
else
    Y_maxim= 0;
    temps= 0;
    azimuth= 0;
end

reduit_elev_vector_taula_final= reduit_elev_vector_taula(1:i-1);
if valor_auxiliar == 0 
    if reduit_elev_vector(1)>12
        reduit_azim_vector_512= reduit_azim_vector;
    else
     reduit_azim_vector_512= reduit_azim_vector(reduit_elev_vector<12 & reduit_elev_vector>fil_el_min);
    end
else
     reduit_azim_vector_512= reduit_azim_vector(reduit_elev_vector<fil_el_max);
end

if auxiliar~=0
    figure;
    pcolor(reduit_elev_vector_taula_final,altures(1:end-1),representacio_final)
    str = sprintf('Average Azimuth =%s',num2str(mean(reduit_azim_vector_512)));
    title(str);
    str1= sprintf('Starts in elevation = %s and finishes in elevation= %s',num2str(reduit_elev_vector(1)),num2str(reduit_elev_vector(end)));
    xlabel(str1)
    ylabel('Height [m]')
    ylim([altures(1) altures(end)])

    reduit_azim_vector_512_final= mean(reduit_azim_vector_512);
    %filename= strcat('Tarifa',doy,'_',num2str(satelit),'_',num2str(tram),'no_interpolat');

     %fname = './Users/Hector/Documents/MATLAB/SNR_Analysis/Tecq_Europe';
     %saveas(gca, fullfile(fname, filename), 'jpeg');
     filename= ['NOUTarifa', num2str(satelit),'_',doy,'_',num2str(tram),'_',num2str(aux_lambda)];
     %saveas(gca, text, 'jpeg');


    if reduit_azim_vector_512_final < 30 && reduit_azim_vector_512_final > 10
        fname = './tarifa_nowavelet/10_30';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 50 && reduit_azim_vector_512_final > 30
        fname = './tarifa_nowavelet/30_50';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 70 && reduit_azim_vector_512_final > 50
        fname = './tarifa_nowavelet/50_70';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 90 && reduit_azim_vector_512_final > 70
        fname = './tarifa_nowavelet/70_90';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 110 && reduit_azim_vector_512_final > 90
        fname = './tarifa_nowavelet/90_110';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 130 && reduit_azim_vector_512_final > 110
        fname = './tarifa_nowavelet/110_130';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 150 && reduit_azim_vector_512_final > 130
        fname = './tarifa_nowavelet/130_150';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 170 && reduit_azim_vector_512_final > 150
        fname = './tarifa_nowavelet/150_170';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 190 && reduit_azim_vector_512_final > 170
        fname = './tarifa_nowavelet/170_190';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 210 && reduit_azim_vector_512_final > 190
        fname = './tarifa_nowavelet/190_210';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 230 && reduit_azim_vector_512_final > 210
        fname = './tarifa_nowavelet/210_230';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 250 && reduit_azim_vector_512_final > 230
        fname = './tarifa_nowavelet/230_250';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 270 && reduit_azim_vector_512_final > 250
        fname = './tarifa_nowavelet/250_270';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    end
    
    close Figure 1
    

end