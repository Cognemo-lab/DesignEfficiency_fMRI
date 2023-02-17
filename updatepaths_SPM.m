% first load the SPM.mat file

pathdataPrevious='/cluster/scratch_xl/shareholder/klaas/dandreea/WAGAD/data';
pathdataNew='/Users/drea/Documents/TNU_Courses/SPM_course/2016/PracticalSession2_DesignEfficiency';
%% To insert:
for i=1:size(SPM.xY.P,1), testP(i,:) = regexprep(SPM.xY.P(i,:), pathdataPrevious, ...
        pathdataNew); end; SPM.xY.P = testP;
for i=1:size(SPM.xY.P,1), SPM.xY.VY(i).fname = regexprep(SPM.xY.VY(i).fname, ...
        pathdataPrevious, pathdataNew); end;
for i=1:size(SPM.xY.P,1), SPM.xY.VY(i).private.dat.fname = regexprep(SPM.xY.VY(i).private.dat.fname, ...
        pathdataPrevious, pathdataNew); end;
