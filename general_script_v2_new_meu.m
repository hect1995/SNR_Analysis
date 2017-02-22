close all;
clear all;
clc;
dia= [01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
dia1= int2strz(dia,2);
for cont= 30:30 
    year='2016';
    month = '12';
    day = dia1(cont,:);
%     station='MAL1';
    station='TARI';

    dayspermonth = [31 29 31 30 31 30 31 31 30 31 30 31]; % days for each month
    fecha = datenum(str2num(year),str2num(month),str2num(day)); %str2num --> Convert character array to numeric array
    doy = num2str(sum(dayspermonth(1:str2num(month)-1))+str2num(day)); % days since starting year

    % RNXCMP --> It converts the format of GNSS observation files from the RINEX format to a compressed format and vice versa
    addpath([cd '/read_teqc_compact']);
    addpath([cd '/RNXCMP_4.0.6_Windows_bcc']); 
    addpath([cd '/RNXCMP_4.0.6_Windows_bcc/bin']);
    addpath([cd '/RNXCMP_4.0.6_Windows_bcc/docs']);

    ngdc = ftp('ftp.geodesia.ign.es'); %The File Transfer Protocol is a standard network protocol used to transfer computer files between a client and server on a computer network
    cd(ngdc,'ERGNSS');
    cd(ngdc,'horario_1s');
    cd(ngdc,[year month day]);
    % ngdc = ftp('epncb.oma.be');
    % dir(ngdc)
    % cd(ngdc,'pub')
    % cd(ngdc,'obs')
    % cd(ngdc,year);
    % cd(ngdc,doy);
    a=dir(ngdc,[station '*N.Z']); %I look for MAL1*N.Z --> GPS efemerides   * vol dir que no omporta el que hi ha abans
    for i=1:1:length(a)
        if isempty(a)==0 %returns 1 if empty, 0 if not
            mget(ngdc,a(i).name); %download file from FTP server
            [status,result] = system(['"C:\Program Files\7-Zip\7z.exe" e -y ' a(i).name]);%I HAVE TO DOWNLOAD 7-ZIP TO COMPRESS
           % [status,result] = system(['unar ' a(i).name]); %e --> extract   -y-->assume yes on all queries

            oldname=[a(i).name(1:end-2)];
            newname=[a(i).name(1:end-3) 'n'];
            dos(['rename "' oldname '" "' newname '"']);
            delete(a(i).name);
    %         delete(oldname);
            orbits_gps=1; %gps
        else
            orbits_gps=0;
            disp('No orbit files');
        end
    end

    a=dir(ngdc,[station '*G.Z']);% GLONASS efemerides. constelacio de satelits en funcio del temps
    % --> * serveix per dir que no t'importa el que hi ha abans que nomes vols buscar els arxius que tenen el G.Z
    for i=1:1:length(a)
        if isempty(a)==0
            mget(ngdc,a(i).name);
            [status,result] = system(['"C:\Program Files\7-Zip\7z.exe" e -y ' a(i).name]);
            oldname=[a(i).name(1:end-2)];
            newname=[a(i).name(1:end-3) 'g'];
            dos(['rename "' oldname '" "' newname '"']);
            delete(a(i).name);
    %         delete(oldname);
            orbits_glonass=1; %glonass
        else
            orbits_glonass=0;
            disp('No orbit files');
        end
    end

    a=dir(ngdc,[station '*d.Z']); %data file . on esta el receptor respecta la constelacio de satelits
    for i=1:1:length(a)
        if isempty(a)==0
            name=a(i).name;
            mget(ngdc,name);
            [status,result] = system(['"C:\Program Files\7-Zip\7z.exe" e -y ' name]);
            delete(name); %delete del arxiu que estava compress.
    %         filename=dir([ '*' doy '*.*d']);
            sentence=['crx2rnx ' name(1:end-2)]; %et genera un fitxer .o en el directori
            dos(sentence); %execute the upper command
            disp([name(1:end-2) ' done']);
            data=1;
        else
            data=0;
            disp('No Data files');
        end
    end

    if data==1&&orbits_glonass==1&&orbits_gps==1 %amb tenir o gps o glonass ja valdria
        filename=dir([ '*' num2str(doy) '*.*o']); %busca tots els  fichers dobservables
        for j=1:1:length(filename)
            sentence=['teqc +plot2 +qc ' filename(j).name]; %pdf  TEQC pag. 44 --> I think it is creating the files .azi .d12 .m12 .sn1 ...
            dos(sentence); 
            % ceras fichers que tnen tots els amps dabaix
        end
        current_path=cd;
    %     data = read_teqc_compact (current_path, [station doy], 'sn1');
        DataL1L2=struct('az',zeros(1,1e7),'el',zeros(1,1e7),'prn',zeros(1,1e7),'epoch',zeros(1,1e7),'sn1',zeros(1,1e7),'sn2',zeros(1,1e7),'sys',zeros(1,1e7),'m12',zeros(1,1e7),'m21',zeros(1,1e7));
        DataL5=struct('az',zeros(1,1e7),'el',zeros(1,1e7),'prn',zeros(1,1e7),'epoch',zeros(1,1e7),'sn5',zeros(1,1e7),'sys',zeros(1,1e7),'m15',zeros(1,1e7),'m51',zeros(1,1e7),'m125',zeros(1,1e7)); %it is useless

        files=dir([station doy '*.sn1']); %they are in COMPACT3 format, ho treu d'aqui perque molta informacio es comuna
        index=1;
        for i=1:1:length(files)
            data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end)); %read_teqc_compact (dir, basename, ext, elev, azim)
            longitud=length(data.obs);
            if strcmp(files(i).name(end-2:end),'sn1')==1 %compare strings and returns 1 if are the same
                  DataL1L2.az(index:index+longitud-1)=data.azi;
                  DataL1L2.el(index:index+longitud-1)=data.ele;
                  DataL1L2.prn(index:index+longitud-1)=data.prn; % com saps la longitud d'aquests vectors?
                  DataL1L2.epoch(index:index+longitud-1)=data.epoch+(i-1)/24;
                  DataL1L2.sn1(index:index+longitud-1)=data.obs;
                  DataL1L2.sys(index:index+longitud-1)=data.sys;
                  index=index+longitud;
            end
        end

        DataL1L2.az = DataL1L2.az(1:index-1); %per nomès deixar el vector amb les mostres necessaries
        DataL1L2.el = DataL1L2.el(1:index-1);
        DataL1L2.prn = DataL1L2.prn(1:index-1);
        DataL1L2.epoch = DataL1L2.epoch(1:index-1);
        DataL1L2.sn1 = DataL1L2.sn1(1:index-1);
        DataL1L2.sn2 = DataL1L2.sn2(1:index-1);
        DataL1L2.m12 = DataL1L2.m12(1:index-1);
        DataL1L2.m21 = DataL1L2.m21(1:index-1);
        DataL1L2.sys = DataL1L2.sys(1:index-1);
        DataL1L2.prn(DataL1L2.sys=='R')=DataL1L2.prn(DataL1L2.sys=='R')+32; %'R'== 82

        %L1 sempre ho tens
        index=1;
        files=dir([station doy '*.sn2']);
        for i=1:1:length(files)
            data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
            longitud=length(data.obs);
            if strcmp(files(i).name(end-2:end),'sn2')==1
                  DataL1L2.sn2(index:index+longitud-1)=data.obs;
                  index=index+longitud;
            end
        end

        index=1;
        files=dir([station doy '*.m12']);
        for i=1:1:length(files)
            data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
            longitud=length(data.obs);
            if strcmp(files(i).name(end-2:end),'m12')==1
                  DataL1L2.m12(index:index+longitud-1)=data.obs;
                  index=index+longitud;
            end
        end

        index=1;
        files=dir([station doy '*.m21']);
        for i=1:1:length(files)
            data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
            longitud=length(data.obs);
            if strcmp(files(i).name(end-2:end),'m21')==1
                  DataL1L2.m21(index:index+longitud-1)=data.obs;
                  index=index+longitud;
            end
        end
% 
% 
%         files=dir([station doy '*.sn5']);
%         index=1;
%         for i=1:1:length(files)
%             data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
%             longitud=length(data.obs);
%             if strcmp(files(i).name(end-2:end),'sn5')==1
%                   DataL5.az(index:index+longitud-1)=data.azi;
%                   DataL5.el(index:index+longitud-1)=data.ele;
%                   DataL5.prn(index:index+longitud-1)=data.prn;
%                   DataL5.epoch(index:index+longitud-1)=data.epoch+(i-1)/24;
%                   DataL5.sn5(index:index+longitud-1)=data.obs;
%                   DataL5.sys(index:index+longitud-1)=data.sys;
%                   index=index+longitud;
%             end
%         end
% 
%         DataL5.az = DataL5.az(1:index-1);
%         DataL5.el = DataL5.el(1:index-1);
%         DataL5.prn = DataL5.prn(1:index-1);
%         DataL5.epoch = DataL5.epoch(1:index-1);
%         DataL5.sn5 = DataL5.sn5(1:index-1);
%         DataL5.m15 = DataL5.m15(1:index-1);
%         DataL5.m51 = DataL5.m51(1:index-1);
%         DataL5.m125 = DataL5.m125(1:index-1);
%         DataL5.sys = DataL5.sys(1:index-1);
%         DataL5.prn(DataL5.sys=='R')=DataL5.prn(DataL5.sys=='R')+32;

%         index=1;
%         files=dir([station doy '*.m15']);
%         for i=1:1:length(files)
%             data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
%             longitud=length(data.obs);
%             if strcmp(files(i).name(end-2:end),'m15')==1
%                   DataL5.m15(index:index+longitud-1)=data.obs;
%                   index=index+longitud;
%             end
%         end

%         index=1;
%         files=dir([station doy '*.m51']);
%         for i=1:1:length(files)
%             data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
%             longitud=length(data.obs);
%             if strcmp(files(i).name(end-2:end),'m51')==1
%                   DataL5.m51(index:index+longitud-1)=data.obs;
%                   index=index+longitud;
%             end
%         end

%         index=1;
%         files=dir([station doy '*.m125']);
%         for i=1:1:length(files)
%             data = read_teqc_compact (current_path, files(i).name(1:end-4), files(i).name(end-2:end));
%             longitud=length(data.obs);
%             if strcmp(files(i).name(end-2:end),'m125')==1
%                   DataL5.m125(index:index+longitud-1)=data.obs;
%                   index=index+longitud;
%             end
%         end

        try
            save([station year(3:4) doy 'struct.mat'],'DataL1L2','-v7');
        catch
            save([station year(3:4) doy 'struct.mat'],'DataL1L2','-v7');
        end

        try
            dataL1L2=struct2table(DataL1L2);
            dataL5=struct2table(DataL5);
            save([station year(3:4) doy 'table.mat'],'dataL1L2' ,'-v7');
        catch
            dataL1L2=struct2table(DataL1L2);
            save([station year(3:4) doy 'table.mat'],'dataL1L2','-v7');
        end  
        delete('*.gz','*.Z',[station doy '*.*'],'brdc*');
    else
        delete('*.gz','*.Z',[station doy '*.*'],'brdc*');
        disp('Not enough data on the servers');
    end

end

