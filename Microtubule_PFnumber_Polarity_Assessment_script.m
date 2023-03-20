% 09.03.2023 CVS
% This script can be used to determine the protofilament number and orientation of microtubules after 
% multireference alignment to 8 references (12, 13, 14, 15 protofilaments each facing the plus and the minus end).
% This script reads in all the 8 refined tables from dynamo multireference alignment
% projects. It then selects the reference with the highest cc-score
% (col 10) for each particle and selects the corresponding class for this microtubule filament.
% It computes the relative frequencies of each class and gives the percentage of the highest value.
% Classes used in our study:
% 1: 12 PF minus, 2: 12 PF plus, 3: 13 PF minus, 4: 13 PF plus, 5: 14 PF
% minus, 6: 14 PF plus, 7; 15 PF minus, 8: 15 PF plus.
% A more detailed description of the script can be found at the bottom.

% Requirements: Dynamo activated in matlab (we used version 1.1.460


% Define the name of the alignment project and the iteration of multireference alignment used.
project_name='MyProjectName';
iteration=1;
date='Todays_date';

% The next three parameters are criteria that can be defined to assign a microtubule protofilament number and polarity. The default values that have worked consistently for our study are the following:
% A microtubule is assigned to a class if 1) at least 50% of its particles classified into the same class (perc_thresh) and the average cc-score (cc_thresh) is at least 0.13 or 2) if at least 65% of particles classified into the same class (pass_perc).
cc_thresh=0.13;
perc_thresh=50;
pass_perc=65;

if not(isfolder(sprintf('%s_Dynamo_Pol_PF_analysis',date)))
       mkdir(sprintf('%s_Dynamo_Pol_PF_analysis',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
end

if not(isfolder(sprintf('%s_Dynamo_Pol_PF_analysis/tabulate',date)))
       mkdir(sprintf('%s_Dynamo_Pol_PF_analysis/tabulate',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
end

if not(isfolder(sprintf('%s_Dynamo_Pol_PF_analysis/modulate',date)))
       mkdir(sprintf('%s_Dynamo_Pol_PF_analysis/modulate',date))
       warning('off', 'MATLAB:MKDIR:DirectoryExists');
end

% PART 1: The first part of the script generates a Dynamo table with alignment results for the class, which resulted in the 'best' alignment based on the cc-score. 
% Read in all the refined table for each reference/ class. Alltbls contains 8 cells, which each contain a dynamo table with particle positions and cc-scores for each reference/ class.
Alltbls=[]
for n=1:8
	Alltbls{n}=dread(sprintf('%s/results/ite_%04d/averages/refined_table_ref_%03d_ite_%04d.tbl',project_name,iteration,n,iteration))
end

% Column 10 in the dynamo table is the cc-score.
% cc_tbl contains cc-scores from all particles for each reference with 8 scores for each particle in one row. It has 8 columns (one cc-score for each class) and the number of rows corresponds to the number of particles used in the alignment.
cc_tbl=[];
for i=1:8
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

% PART 2: The following steps are in place to determine the number of particles per microtubule that classified into each class. Based on the parameters given at the beginning of the script, this will result in the assignment of microtubule protofilament number and polarity.
% Generally, the script finds all the particles in one microtubule (determined by the model number in column 6), removes the worst 20 % of particles based on their cc-scores and then checks how many particles of the remaining array in that microtubule classified into each of the 8 classes. If the microtubule passes the criteria given at the beginning of the script, the microtubule polarity is 'assigned' and the number of the final class is added to the table. 
% The MTtbl contains 8 columns. column 1: Class number that gave the maximum cc-score for each particle within the microtubule. column 2: class, number of particles in this class and percentage of particles in this class for each microtubule, column 3: tomogram number (column 20), column 4: model number (column 6), column 5: most frequent class number, column 6: Percentage of the most frequent class number, column 7: average cc-score of the microtubule. The cc-score of the best alignment is considered for each particle. column 8: Class assigned to the microtubule.
allMTs=[];
MTtbl=[];
clean_tbl=[];
for i=1:length(unique(besttbl(:,21)))
	%find all rows with particles from that model
	mod=find(besttbl(:,21)==i);
	mod_tbl=besttbl(mod,:);
	% Generate a besttbl (containing particle transformation, angles, etc. and the class number from the class to which the particle aligned best based on its cc-score) per model and sort it by cc-score 	(column 10). Descending meaning best cc-scores at the top.
	sort_mod=sortrows(mod_tbl,10,'descend');
	% Get indices of the top 80% of the data (simply by taking the upmost indices).
	% Make a cleaned model table. This table will be sorted by cc-score and will therefore have a different order from the original one. Use the ceiling command to round the percentage value.
	clean_mod=sort_mod(1:ceil(0.8*size(sort_mod,1)),:);
	clean_tbl=[clean_tbl' clean_mod']';
	% This adds the reference number (class) that gave the maximum cc-score for each particle to the MTtbl matrix
    	MTtbl{i,1}=clean_mod(:,23);
    	csvwrite(sprintf('%s_Dynamo_Pol_PF_analysis/modulate/%s_cleaned_modulate_mod_%03d.csv',date,date,i),MTtbl{i,1})
	% tabulate calculates the frequency distribution of particles in each class with counts and percentages. The tabulate output files have three columns: Class, number of particles in this class, 		percentage of particles in this class.
	MTtbl{i,2}=tabulate(MTtbl{i,1});
    	csvwrite(sprintf('%s_Dynamo_Pol_PF_analysis/tabulate/%s_cleaned_tabulate_mod_%03d.csv',date,date,i),MTtbl{i,2})
    	% Get tomogram (column 20) and model (column 21) number.
	MTtbl{i,3}=unique(Alltbls{1}(mod,20));
    	MTtbl{i,4}=unique(Alltbls{1}(mod,21));
	% mode finds the most frequent number in the 1-row array
	MTtbl{i,5}=mode(MTtbl{i,1});
	% This gives the percentage of the best reference
	MTtbl{i,6}=max(MTtbl{i,2}(:,3));
    	% This gives the average of all cc-scores in the best rated alignment for that particle.
    	MTtbl{i,7}=mean(cc_tbl(MTtbl{i,5},mod));
    	% If a microtubule matches the criteria given at the top of the script, this microtubule is assigned, i. e. the assigned class number (1 - 8) is added into column 8. If the microtubule cannot be 		assigned, 0 is added to column 8.
    	if (MTtbl{i,7}>=cc_thresh && MTtbl{i,6}>=perc_thresh) || MTtbl{i,6}>=pass_perc
        	MTtbl{i,8}=MTtbl{i,5};
    	else
        	MTtbl{i,8}=0;
    	end
end	

% Only columns 3 - 6 are written out here into a csv file where the last column is the assigned class number.
csvwrite(sprintf('%s_Pol_PF_MRA_%sccthresh_%spercthresh_matlab.csv',date,cc_thresh,perc_thresh),MTtbl(:,3:8))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% Brief description of what the script does:
%
% 1. Reads in all 8 reference tables (from any given iteration) and extracts all 8 cc-scores from each table (cc_tbl).
% 2. It then find the index of the table with the highest cc-score for each particle and makes an array of the highest scoring reference for each particle (I). This array is pasted into col23 of the 'besttbl'.
% 3. It generates the besttbl containing all the alignment information of the highest scoring alignment and the class in col 23. This is what subTOM gives you straight away in a single table whereas dynamo makes 8 tables (for 8 references). This is the longest process because I scripted this in a loop.
% 4. For each model, it generates a 'clean' particle table containing the best 80 % of the data based on the cc-score (clean_mod). In then assembles all the clean model tables into a clean table (clean_tbl). At the moment, this table is not being saved.
%   The way it gets the best 80 percent is by extracting all rows from one model, sorting by cc-score (col 10) and then calculating how many rows it needs. It uses the ceiling function to round the value and get integers for extracting the amount of columns.
% 5. Generate the final read-out: Make the MTtbl that contains in cols 1-8:
%   1) an array of the best scoring class of each particle in the cleaned model. Each row is one model
%   2) the frequency distribution of each class in this model. This is done on the cleaned model using the tabulate function. Each row is one model
%   3) Tomo number (this is for copy and paste into excel)
%   4) Model number (this is for copy and paste into excel)
%   5) The most frequent class number for this model. This is done from the cleaned table using the mode function.
%   6) Percentage of the highest scoring reference in that model compared to all other references for this model. This is done from the cleaned mod table.
%   7) Mean cc-score for each filament of the cleaned tbl for all the best scoring class.
%   8) This is the repeated array from col 5 but this time considering if that value is trustworthy. The criteria have been adjusted from tests on three separate datasets. They are as follows:
%   One way of passing is that the mean cc-score is => 0.13 AND the percentage of the highest scoring class is =>50%. Alternatively, if =>65% of particles in are in one class, the cc-score becomes irrelevant and the model passes the criterium.
%6. The final matrix, the tabulate and the mode tables are written out into csv files.
%
% These are the reference numbers and corresponding protofilament (PF) numbers and oritentations:
% 1: 12 PF, minus
% 2: 12 PF, plus
% 3: 13 PF, minus
% 4: 13 PF, plus
% 5: 14 PF, minus
% 6: 14 PF, plus
% 7: 15 PF, minus
% 8: 15 PF, plus 
%
