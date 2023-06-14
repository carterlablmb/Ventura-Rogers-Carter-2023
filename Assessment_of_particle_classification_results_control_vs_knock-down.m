% This script was used to determine the number of particles from control  or cofilin knock-down cells from each biological replicate in each category of class (cofilactin, bare f-actin, other). 
% It uses classification results from Relion but starts with the Dynamo table. The Relion 3 star file can be converted to a Dynamo table using Alister Burt's dynamo2m package (https://github.com/alisterburt/dynamo2m). Not all information is transferred and additional columns from Relion star files can be extracted with Sami Chaaban's Starparser (https://github.com/sami-chaaban/starparser) using the --list_column option. The extracted column can then be added into the Dynamo table in MATLAB (see below). 
% DS means dataset and is equivalent to biological replicate in this experiment. Datasets 9-12 (DS9 - DS12) were used for this classification, each containing particles from control and knock-down cells.
% CV 14.06.2023 

path='path-to-the-Relion-3DClass-job' %for example '/Relion/Class3D/job001/'
tbl_name='Dynamo_table_name.tbl'

% Cofilactin like classes (f.e. [1,3,5]: 
Cofilactin_array=[];
% Bare f-actin-like classes (f.e. [2,4]: 
Actin_array=[];
% Classes with neither cofilactin nor bare f-actin morphology: 
Other_array=[];

% Read dynamo table and extracted columns with te tomogram number, Class number, Filament number (extracted from the Relion star file with Starparser). These columns are added to the Dynamo table
% Following the Dynamo convention, column 20 has the tomogram number, column 21 the model (i.e. filament) number and column 23 the class number.
tbl=dread(strcat(path,tbl_name));
TS_number=csvread(strcat(path,'TSNb.txt'));
Class_number=csvread(strcat(path,'ClassNumber.txt'));
Fil_number=csvread(strcat(path,'FilamentNb.txt'));
tbl(:,20)=TS_number;
tbl(:,21)=Fil_number;
tbl(:,23)=Class_number;
% Check if the tomogram numbers have been correctly added.
TS_array=unique(tbl(:,20));

% Assign tomogram numbers belonging to the COF or CAT KDs from the different biological replicates/ datasets. 
DS9_COF_TSarray=330:351;
DS9_CAT_TSarray=[352:366 462:470];
DS10_COF_TSarray=424:442;
DS10_CAT_TSarray=443:461;
DS11_COF_TSarray=[495:505 367 371 380];
DS11_CAT_TSarray=506:527;
DS12_COF_TSarray=528:540;
DS12_CAT_TSarray=542:556;

% Generate Dynamo tables for each dataset and condition (control vs. knock-down).
% ismember finds row indices where column 20 (tomogram name) has any value in array DS9_COF_TSarray defined above.
DS9_COF_tbl=tbl(ismember(tbl(:,20),DS9_COF_TSarray),:); 
DS9_CAT_tbl=tbl(ismember(tbl(:,20),DS9_CAT_TSarray),:); 
DS10_COF_tbl=tbl(ismember(tbl(:,20),DS10_COF_TSarray),:); 
DS10_CAT_tbl=tbl(ismember(tbl(:,20),DS10_CAT_TSarray),:); 
DS11_COF_tbl=tbl(ismember(tbl(:,20),DS11_COF_TSarray),:); 
DS11_CAT_tbl=tbl(ismember(tbl(:,20),DS11_CAT_TSarray),:); 
DS12_COF_tbl=tbl(ismember(tbl(:,20),DS12_COF_TSarray),:); 
DS12_CAT_tbl=tbl(ismember(tbl(:,20),DS12_CAT_TSarray),:);

% Determine class distribution in each dataset and condition (control vs. knock-down) and also for all datasets together. For each dataset and condition, a particle class distribution is prepared and pasted into cells of Distribution (Distribution{1,1} has the 5x3 matrix with class number (column 1), particle number (column 2), particle percentage (column 3) for dataset 9, knock-down.
% tabulate calculates the frequency distribution with counts (absolute values) and percentages. It generates three columns with 1. Quantified value (f.e. class number), 2. count, 3. percentage.
Distribution=[];
Distribution{1,1}=tabulate(DS9_COF_tbl(:,23))
Distribution{1,2}=tabulate(DS9_CAT_tbl(:,23))
Distribution{1,3}=tabulate(DS10_COF_tbl(:,23))
Distribution{1,4}=tabulate(DS10_CAT_tbl(:,23))
Distribution{1,5}=tabulate(DS11_COF_tbl(:,23))
Distribution{1,6}=tabulate(DS11_CAT_tbl(:,23))
Distribution{1,7}=tabulate(DS12_COF_tbl(:,23))
Distribution{1,8}=tabulate(DS12_CAT_tbl(:,23))

% Generation of a single table with all particle counts (i.e. number of particles in each class).
% perPtl_DistrAll: 5x8 matrix. Column 1 contains particle counts for classes 1-5 from DS9 knock-down in each row. Column 2 is the same for DS9 control. Columns 3-8 are equivalent. 
perPtl_DistrALL=[];
for i=1:8
	perPtl_DistrALL(:,i)=Distribution{1,i}(:,2);
end
csvwrite(strcat(path,'AllParticles_ClassDistribution_Col1Class_Col2PtlNb_Col3Perc.csv'),Distribution)

% perPtl_Distr_COFKD: is equivalent to perPtl_DistrALL but only for knock-down data. (5x4 matrix)
perPtl_Distr_COFKD=[];
n=0
for i=[1,3,5,7]
	n=n+1
	perPtl_Distr_COFKD(:,n)=Distribution{1,i}(:,2); 
end
csvwrite(strcat(path,'COF_KD_ClassDistribution_BiolReplPerColumn.csv'),perPtl_Distr_COFKD)

% perPtl_Distr_CATKD: is equivalent to perPtl_DistrALL but only for control data. (5x4 matrix)
perPtl_Distr_CATKD=[];
n=0
for i=[2,4,6,8]
	n=n+1
	perPtl_Distr_CATKD(:,n)=Distribution{1,i}(:,2); 
end
csvwrite(strcat(path,'CAT_KD_ClassDistribution_BiolReplPerColumn.csv'),perPtl_Distr_CATKD)


% Cofilactin: Number of particles in cofilactin-like classes for each dataset and condition. The cofilactin_array lists classes with cofilactin-like morphology (defined at the beginning of the script).
% Row 1: particles in cofilactin-like classes from knock-down dataset 9 (column 1), 10 (column 2), dataset 11 (column 3), dataset 12 (column 4). 
% Row 2: particles in cofilactin-like classes from control dataset 9 (column 1), 10 (column 2), dataset 11 (column 3), dataset 12 (column 4). 
Cofilactin=[];
Cofilactin(1,1:4)=sum(perPtl_Distr_COFKD(Cofilactin_array,:),1);
Cofilactin(2,1:4)=sum(perPtl_Distr_CATKD(Cofilactin_array,:),1);

% Equivalent to the previous 'Cofilactin' section for bare f-actin.
Actin=[];
Actin(1,1:4)=sum(perPtl_Distr_COFKD(Actin_array,:),1);
Actin(2,1:4)=sum(perPtl_Distr_CATKD(Actin_array,:),1);

% Equivalent to the previous 'Cofilactin' section for 'other' classes (neither cofilactin nor bare f-actin morphology).
Other=[];
Other(1,1:4)=sum(perPtl_Distr_COFKD(Other_array,:),1);
Other(2,1:4)=sum(perPtl_Distr_CATKD(Other_array,:),1);

% 'Cofilactin', 'Actin', 'Other' arrays were transferred to Excel/ Graphpad Prism spreadsheets for statistical analysis and figure preparation.
