CSE 572
Fall 2017

TEAM MEMBERS
Jigar Domadia (jdomadia@asu.edu)
Joseph Campbell (jacampb1@asu.edu)
Rajrshi Raj Shrestha (rrshrest@asu.edu)
Sai Pramod Kolli (skolli6@asu.edu)

Instructions on running code:

Copy the EMG and IMU data into EMG and IMU folder located inside "AllData" directory.
We have included our copy of Annotations since we have modified them but the raw data is too large to be included in our submission.


    %	DataParser_P4
    %   Example usage:
    %   >> parser = DataParser_P4('AllData')
    %   >> [eat_mat, noneat_mat, group_action_indices] = parser.parse_data();
    %   >> parser.export_data(eat_mat, 'eat_data.csv')
    %   >> parser.export_data(noneat_mat, 'noneat_data.csv')
    %   >> parser.export_group_mappings(group_action_indices, 'mapping.csv');
	
	% DataAnalysis (pre-requisite)
    %   >> analyzer = DataAnalysis('eat_data.csv', 'noneat_data.csv', 'mapping.csv')
    %   >> [coeff, score, latent, explained] = analyzer.analyze_pca;
    %   >> analyzer.export_pca_data('eat_pca.csv', 'noneat_pca.csv');
	
	%	DataAnalysis_DT
    %   Example Usage:
    %   >> analyzer.analyze_dt();

	
	%	DataAnalysis_SVM
    %   Example Usage:
    %   >> analyzer.analyze_svm();
	
	
	%   DataAnalysis_NN
    %   Example Usage:
    %   >> analyzer.analyze_nn();
	