% 230312 CV 
% This script can be used to do preliminary sorting of luminal filament polarity 
% after multireference alignment into two classes (which represent filaments with 
% opposing polarities) in Dynamo. We perform this preliminary polarity sorting at 
% bin4 (10 - 12 A/ pixel) to obtain a good references more easily for refinements
% in Relion 3.1. However, results from this preliminary sorting are not 'final' 
% and usually required further reorientation after classification in Relion 3.1.
% 
% This script reads in the 2 refined tables from Dynamo multiref alignment
% projects. The script then selects the reference with the highest cc-score
% (col 10) for each particle and selects the corresponding class.
% It computes the relative frequencies of each class and gives the 
% percentage of the highest scoring class.

% The script also flips the particle table to obtain a particle set with 
% uniformly oriented (same polarity) particles 

% Classes used in our study:
% 1: filament with polarity 1
% 2: filament with polarity 2 (opposite to polarity 1)

% Requirements: 
% - Dynamo activated in MATLAB (we used version 1.1.460
% - subTOM (we used version 1.1.2)


% Add the path to subTOM MOTL utilities in MATLAB
addpath('path-to/subTOM/src/MOTL','-end');

% Define the name of the alignment project and the iteration of multireference alignment used.
project_name='MyProjectName';
subtomograms='path-to-cropped-subtomograms';
iteration=1;
date='Todays_date';

% The next three parameters are criteria that can be defined to assign the luminal filament polarity. Because most luminal filaments are too short to give high-cotrast per-filament averages, we have set these criteria so that basically all filaments 'pass' and are assigned to the polarity with at least 50% of particles. If equal numbers of particles classified into class 1 and class 2, class 1 will be assigned. 
% A filament is assigned to a class if 1) at least 50% of its particles classified into the same class (perc_thresh) and the average cc-score (cc_thresh) is at least 0.01 (this value is extremely low and essentially makes sure that all filaments will be assigned. Increasing this value will make the polarity determination more conservative and remove filaments whose polarity could not be unambiguously determined) or 2) if at least 65% of particles classified into the same class (pass_perc) (this second criterium is irrelevant if the cc-thresh value is retained very low. It the cc_thresh value is increased, this criterium can help maintain filaments within the project if their polarity can be more confidently assigned but their cc-score is low).
cc_thresh=0.01;
perc_thresh=50;
pass_perc=65;

% Options for the script
% set this to 1 if you'd like to generate an assigned table for flipping and flip it. 
% IMPORTANT: Flipping is only performed for 13 PF microtubules (classes 3, 4). The final
% flipped table will only cnotain 13 PF microtubules!
flip_table=0; 

%set this to 1 if you want a written out motl for display of PF trasitions in matlab. 
%To use the motl_with_class option, you need to run the bash
%tomoname_tomoidx script and produce a file with the name: tomoidx_tomoname.txt
motl_with_class=0; 

% Set this to 1 if you want to generate per model (i. e. filament) averages.
Ind_LA_avg=0; %set this to 1 if you want to do individual filament averaging.

if not(isfolder(sprintf('%s_Dynamo_Pol_analysis',date)))
       mkdir(sprintf('%s_Dynamo_Pol_analysis',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
end

if not(isfolder(sprintf('%s_Dynamo_Pol_analysis/tabulate',date)))
       mkdir(sprintf('%s_Dynamo_Pol_analysis/tabulate',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
end

if not(isfolder(sprintf('%s_Dynamo_Pol_analysis/modulate',date)))
       mkdir(sprintf('%s_Dynamo_Pol_analysis/modulate',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
end

if motl_with_class==1
    if not(isfolder(sprintf('%s_Pol_analysis/2Cl',date)))
       mkdir(sprintf('%s_Pol_analysis/2Cl',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
    end
end


% PART 1: The first part of the script generates a Dynamo table with alignment results for the class, which resulted in the 'best' alignment based on the cc-score. 
% Read in all the refined table for each reference/ class. Alltbls contains 8 cells, which each contain a dynamo table with particle positions and cc-scores for each reference/ class.
Alltbls=[]
for n=1:2
	Alltbls{n}=dread(sprintf('%s/results/ite_%04d/averages/refined_table_ref_%03d_ite_%04d.tbl',project_name,iteration,n,iteration))
end

% Column 10 in the dynamo table is the cc-score.
% cc_tbl contains cc-scores from all particles for each reference with 8 scores for each particle in one row. It has 8 columns (one cc-score for each class) and the number of rows corresponds to the number of particles used in the alignment.
cc_tbl=[];
for i=1:2
	cc_tbl(:,i)=Alltbls{i}(:,10);
end

% Transpose the matrix because the max(A) function finds the highest value in each column and gives the indices of each row.
cc_tbl=cc_tbl';

% max(A) finds the row index with the maximum value in each column, which corresponds to the class for which the particle had the highest cc-score, and the highest cc-score value. M is an array of the highest cc-score per particle (each particle is one column). I is an array with the index of the row with the highest cc-score (one particle per column) and this corresponds to the class to which each particle classified (i.e. highest cc-score).
[M,I] = max(cc_tbl);

% This generates a table with the best alignment parameters by chosing the dynamo refinement table belonging to the class that scored highest (i.e. with the highest cc-score) for each particle. This step can take a couple of minutes if the alignment was run on a lot of particles. This is a very inelegant way of doing this but it works.
% In the resulting besttbl, each particle is in one row, following the dynamo table convention.
besttbl=[];
for n=1:length(Alltbls{1})
	besttbl=[besttbl' Alltbls{I(n)}(n,:)']';
end
besttbl(:,23)=I';


% PART 2: The following steps are in place to determine the number of particles per filament that classified into each class. Based on the parameters given at the beginning of the script, this will result in the assignment of filament polarity.
% Generally, the script finds all the particles in one filament (determined by the model number in column 6), removes the worst 20 % of particles based on their cc-scores and then checks how many particles of the remaining array in that filament classified into each of the 2 classes. If the filament passes the criteria given at the beginning of the script, the filament polarity is 'assigned' and the number of the final class is added to the table. 
% The Filtbl contains 8 columns. column 1: Class number that gave the maximum cc-score for each particle within the filament. column 2: class, number of particles in this class and percentage of particles in this class for each filament, column 3: tomogram number (column 20), column 4: model number (column 6), column 5: most frequent class number, column 6: Percentage of the most frequent class number, column 7: average cc-score of the filament. The cc-score of the best alignment is considered for each particle. column 8: Class assigned to the filament.

Filtbl=[];
clean_tbl=[];
for i=1:length(unique(besttbl(:,21)))
	% Find all rows with particles from that model
	mod=find(besttbl(:,21)==i);
	mod_tbl=besttbl(mod,:);
	% Generate a besttbl (containing particle transformation, angles, etc. and the class number from the class to which the particle aligned best based on its cc-score) per 	 % model and sort it by cc-score (column 10). Descending meaning best cc-scores at the top.
	sort_mod=sortrows(mod_tbl,10,'descend');
	% Get indices of the top 80% of the data (simply by taking the upmost indices)
	% Make a cleaned model table. This table will be sorted by cc value and therefore different from the original one. Use the ceiling command to round the percentage value.
	clean_mod=sort_mod(1:ceil(0.8*size(sort_mod,1)),:);
	clean_tbl=[clean_tbl' clean_mod']';
	% This adds the reference number that gave the maximum cc-score for each particle to the Filtbl matrix
    	Filtbl{i,1}=clean_mod(:,23);
    	csvwrite(sprintf('%s_Dynamo_Pol_analysis/modulate/%s_cleaned_modulate_mod_%03d.csv',date,date,i),Filtbl{i,1})
	% tabulate calculates the frequency distribution of particles in each class with counts and percentages. The tabulate output files have three columns: Class, number of 	particles in this class, percentage of particles in this class.
	Filtbl{i,2}=tabulate(Filtbl{i,1});
    	csvwrite(sprintf('%s_Dynamo_Pol_analysis/tabulate/%s_cleaned_tabulate_mod_%03d.csv',date,date,i),Filtbl{i,2})
    	% Get tomo (col20) and mod (col 21) number.
	Filtbl{i,3}=unique(Alltbls{1}(mod,20));
    	Filtbl{i,4}=unique(Alltbls{1}(mod,21));
	% mode finds the most frequent number in the 1-row array
	Filtbl{i,5}=mode(Filtbl{i,1});
	% This gives the percentage of the best reference
	Filtbl{i,6}=max(Filtbl{i,2}(:,3));
    	% This gives the avg of all cc-scores in the best rated alignment (class) for that particle
    	Filtbl{i,7}=mean(cc_tbl(Filtbl{i,5},mod));
    	% If a microtubule matches the criteria given at the top of the script, this microtubule is assigned, i. e. the assigned class number (1 - 8) is added into column 8. If 	the microtubule cannot be assigned, 0 is added to column 8.
    	if (Filtbl{i,7}>=cc_thresh && Filtbl{i,6}>=perc_thresh) || Filtbl{i,6}>=pass_perc
        	Filtbl{i,8}=Filtbl{i,5};
    	else
        	Filtbl{i,8}=0;
    	end
end	

% Only columns 3 - 6 are written out here into a csv file where the last column is the assigned class number.
csvwrite(sprintf('%s_Pol_MRA_%sccthresh_%spercthresh_matlab.csv',date,cc_thresh,perc_thresh),Filtbl(:,3:6))

% Generation of the 'assigned table' where all particles in one model (filament)
% have the same class number (column 23). This needs to be generated to flip all
% particles in that model.
model_array=(unique(besttbl(:,21)))';
assigned_tbl=[];
for i=model_array
	n=i;
	dtgrep(besttbl,'grep_column',21,'grep_selection',i,'ws','microtubule_tbl')
	microtubule_tbl(:,23)=cell2mat(Filtbl(i,8));
	assigned_tbl=[assigned_tbl' microtubule_tbl']';
	% If Ind_LA is set to 1 at the beginning of the script, each filament will be averaged individually.
	% If Ind_LA is set to 0, this process will be skipped.
    	if Ind_LA_avg==1
        	daverage(subtomograms,'t',microtubule_tbl,'ws','LA_avg')
        	All_avg{n}=LA_avg.average
        	write=sprintf(strcat(project_name,'/LA_avg/lastite_mod_%03d_avg.em'),n)
        	dwrite(All_avg{n},write)
    	end        
end

% OPTIONAL: This part of the script will split the particle table based on the assigned class 
% (i. e. polarity) and rotate one class by -180 degrees around the second Euler angle to 
% obtain a particle set with uniform filament polarity.
% This part will only be executed it flip_table is set to 1 at the beginning of the script.

% Important: we use the original crop table for this rotation, not the aligned table in which 
% particles may have shifted on top of each other. The original table can be found in the folder
% with cropped subtomograms.

if flip_table==1
    % Read in the original crop table.
    orig_tbl=dread(strcat(subtomograms,'crop.tbl'));
    % Save particles with class 1 in one Dynamo table.
    orig_tbl_for_flip=orig_tbl(find(assigned_tbl(:,23)==1),:);
    dwrite(orig_tbl_for_flip,sprintf('%s_orig_tbl_LA_Pol1_forFlip.tbl',date))
    % Save particles with class 2 in a separate Dynamo table.
    orig_tbl_noFlip=orig_tbl(find(assigned_tbl(:,23)==2),:);
    dwrite(orig_tbl_noFlip,sprintf('%s_orig_tbl_LA_Pol2_noFlip.tbl',date))
    % Convert the dynamo table from class 1 to a subTOM motive list (MOTL) and save.
    motl_forFlip=dynamo__table2motl(orig_tbl_for_flip);
    dwrite(motl_forFlip,sprintf('%s_orig_tbl_LA_Pol1_forFlip_motl.em',date))
    % Rotate the MOTL from class 1 by -180 degrees around the second Euler angle (theta)
    subtom_transform_motl(...
    'input_motl_fn',sprintf('%s_orig_tbl_LA_Pol1_forFlip_motl.em',date),...
    'output_motl_fn', sprintf('%s_orig_tbl_LA_Pol1_-180theta_afterFLIP.em',date),...
    'shift_x', 0,...
    'shift_y', 0,...
    'shift_z', 0,...
    'rotate_phi', 0,...
    'rotate_psi', 0,...
    'rotate_theta', -180,...
    'rand_inplane', 0)
    % Read in the rotated MOTL and convert back into a Dynamo table.
    Flipmotl=dread(sprintf('%s_orig_tbl_LA_Pol1_-180theta_afterFLIP.em',date));
    flipDyntbl=dynamo__motl2table(Flipmotl);
    % Copy the angles after rotation into the original orig_tbl_for_flip (angles are columns 7-9)
    FINAL_AfterFlip=orig_tbl_for_flip;
    FINAL_AfterFlip(:,7:9)=flipDyntbl(:,7:9);
    % Combine the original table for class 2 with the rotated table for class 1.
    FINAL_assembled_table=[FINAL_AfterFlip' orig_tbl_noFlip']';
    FINAL_sort_tbl=sortrows(FINAL_assembled_table,1);
    % Save the combined particle table.
    dwrite(FINAL_sort_tbl,sprintf('%s_orig_tbl_LA_PolFlipped_sorted.tbl',date))
end

csvwrite(sprintf('221007_%s_FilmodelArray.csv',date),FINAL_sort_tbl(:,21))

% OPTIONAL: This part of the script converts the Dynamo table into a motive list (MOTL) which can be used 
% to visualize particles in Chimera on the tomogram using the Chimera plugin from Qu, et al 2018.
% This part requires a file called tomoidx_tomoname.txt which contains the indices and the tomogram name.
% A separate bash script generating this file will be uploaded to run in the terminal. 
if motl_with_class==1
    motl_class=dynamo__table2motl(besttbl);
    motlrows = size(motl_class,1); % size of the first dimension of the motl tbl. should be 20
    motlcolumns = size(motl_class,2); %s econd dim (columns) amount of particles
    dynrows = size(besttbl,1); % particle nb
    dyncolumn = size(besttbl,2); % nb of columns in dynamo table (35)
    % update tomo name from file name (row 7 in motl). 
    tomo_name = readmatrix('tomoidx_tomoname.txt');
    % change the tomogram index to the real tomogram number (row 7 of the MOTL, column 20 of the Dynamo table).
    for i=1:length(tomo_name)
        q=find(motl_class(5,:)==i);
        motl_class(7,[q])=tomo_name(i);
    end
    % update the model nb (row 6 of the MOTL, column 21 of the Dynamo table)
    for i=1:dynrows
        model_numbers=besttbl(i,21);
        motl_class(6,i) = model_numbers;
    end
    % update class number into row 20 of the motl. 
    for i=1:dynrows
        class_nb=besttbl(i,23);
        motl_class(20,i) = class_nb;
    end
    dwrite(motl_class, sprintf('%s_BestTbl_cl1-2_motl_%sccthresh_%spercthresh.em',date,cc_thresh,perc_thresh))
    % This generates two MOTLs which contain particles from either class 1 (polarity 1) or class 2 (polarity 2). 
    % These two MOTLs are saved separately.
    l=find(motl_class(20,:)==2);
    motl_2cl=motl_class;
    motl_2cl(20,l)=1;
    dwrite(motl_2cl, sprintf('%s_BestTbl_cl12_2cl_motl_%sccthresh_%spercthresh.em',date,cc_thresh,perc_thresh))
    subtom_split_motl_by_row('input_motl_fn', sprintf('%s_BestTbl_cl1-2_motl_%sccthresh_%spercthresh.em',date,cc_thresh,perc_thresh),...
         'output_motl_fn_prefix', sprintf('%s_Pol_analysis/2Cl/motl_TS',date),...
         'split_row', 7)
    subtom_split_motl_by_row('input_motl_fn', sprintf('%s_BestTbl_cl12_2cl_motl_%sccthresh_%spercthresh.em',date,cc_thresh,perc_thresh),...
         'output_motl_fn_prefix', sprintf('%s_Pol_analysis/2Cl/motl_TS',date),...
         'split_row', 7)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% Brief description of what the script does step-by-step. In short it:
%
% 1. Reads in the 2 reference tables (from it0001) and extracts the cc-scores from each table (cc_tbl).
% 2. It then finds the index of the table with the highest cc-score for each particle and makes an array of the highest scoring reference for each particle (I). This array is pasted into column 23 of the 'besttbl'.
% 3. It generates the besttbl containing all the alignment information of the highest scoring alignment and the class in column 23. This is a very inelegant way of generating a single table from the mulitreference alignment that only contains the information from the 'best' alignment (based on the cc-score). I am sure there are better ways of doing this than in a for loop. 
% 4. For each model, it generates a 'clean' particle table containing the best 80 % of the data based on the cc-score (clean_mod). In then assembles all the clean model tables into a clean table (clean_tbl). At the moment, this table is not being saved.
%   The way it gets the best 80 percent is by extracting all rows from one model, sorting by cc-score (col 10) and then calculating how many rows it needs. It uses the ceiling function to round the value and get integers for extracting the amount of columns.
% 5. Generate the final read-out: Make the Filtbl that contains in cols 1-8:
%   1) an array of the best scoring class of each particle in the cleaned model. Each row is one model
%   2) the frequency distribution of each class in this model. This is done on the cleaned model using the tabulate function. Each row is one model
%   3) Tomo number (this is for copy and paste into excel)
%   4) Model number (this is for copy and paste into excel)
%   5) The most frequent class number for this model. This is done from the cleaned table using the mod function.
%   6) Percentage of the highest scoring reference in that model compared to all other references for this model. This is done from the cleaned mod table.
%   7) Mean cc-score for each filament of the cleaned tbl for all the best scoring class.
%   8) This is the repeated array from col 5 but this time considering if that value is trustworthy. 
% 6. The final matrix, the tabulate and the mode tables are written out into csv files.
%
%References code (this of course depends on which references were given for the alignment but I now have it consistent):
% Class 1: Pol 1, this will be flipped
% Class 2: Pol 2, this one will not be flipped
